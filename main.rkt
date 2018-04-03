#lang racket

(require msgpack)

(provide start-client
         stop-client
         rpc-call
         rpc-notify)

;; Datatypes and internal constructors
(struct request (type msgid method params))
;;; TODO Right now, this will fail if given non-Packable types
(define (make-request msgid method params)
  (let  ([data #(0 msgid method params)])
    (call-with-output-bytes (lambda (out) (pack data out)))))

(struct response (type msgid err result))
;;; We assume that the server only gives us good responses, which is almost certainly a terrible
;;; idea
(define (make-response-handler cust)
  (parameterize ([current-custodian cust])
                (let ([callback-channel (make-channel)])
                  (define (response-handler data)
                    (match data
                           [(response 1 msgid err result) (channel-put callback-channel (values err result))]))
                  response-handler)))

(struct notify (type method params))
(define (make-notify method params)
  (let ([data #(2 method params)])
    (call-with-output-bytes (lambda (out) (pack data out)))))

;; Making a call
(define (rpc-call client method [sync? #t] . args)
  (match sync?
    [#t (send client sync-call method args)]
    [#f (send client async-call method args)]))

(define (rpc-notify client method . args)
  (send client sync-notify method args))

;; Client management
(define (start-client addr [port-num nil] [conn-type "unix"])
  (let ([client (new rpc-client% [address addr] [port-num port-num] [connection-type conn-type])])
    (send client start)
    client))

(define (stop-client client)
  (send client stop))

;; The RPC Client class
;;; TODO All methods that require the client to be started should check that it has been started
;;; TODO Error checking & exceptions
(define rpc-client%
  (class object%
         (init-field address [port-num nil] [connection-type "unix"])
         (super-new)
         (define next-id-num 0)
         (define loop nil)
         (define pending-requests (make-hash))
         (define client-cust (make-custodian))
         ;;; Initialized as nil so that the custodian can manage them
         (define in nil)
         (define out nil)
         ;;; Generate next valid 32-bit integer msgid
         (define/private (next-id) (if (< next-id-num (sub1 (expt 2 32))) (add1 next-id-num) 0))
         (define/public (stop) (custodian-shutdown-all client-cust))
         ;;; TODO Check address+port for validity for given connection method
         ;;; TODO UDP support
         (define/private (connect)
           (match connection-type
                  ["unix" (unix-socket-connect address)]
                  ["tcp" (tcp-connect address port-num)]))
         ;;; TODO Timeouts should be a (configurable) feature
         (define/public (start)
           (parameterize ([current-custodian client-cust])
                         (let-values ([(in-chan out-chan) (connect)])
                           (set! in in-chan)
                           (set! out out-chan))
                         (set! loop
                               (thread
                                 (lambda ()
                                   (let loop ()
                                     (sync
                                       (handle-evt in
                                                   ;;; We assume that the client only ever gets responses back. This is
                                                   ;;; maybe a bad assumption
                                                   (lambda (evt) (dispatch-response (unpack evt)))))
                                     (loop)))))))
         (define/private (dispatch-response data)
           ((hash-ref pending-requests (vector-ref data 1)) data))
         (define/private (send-request method args)
           (let-values ([(request-bytes) (make-request next-id-num method args)]
                        [(callback-channel callback-handler) (make-response-handler client-cust)])
             (hash-set! pending-requests next-id-num callback-handler)
             (next-id)
             (display request-bytes out)
             callback-channel))
         (define/public (sync-call method args)
           (let ([callback-channel (send-request method args)])
             (channel-get callback-channel)))
         (define/public (async-call method args)
           (let ([callback-channel (send-request method args)])
             callback-channel))
         (define/public (sync-notify method args)
           (display (make-notify method args) out))))
