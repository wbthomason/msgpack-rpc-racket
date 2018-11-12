#lang racket

(require racket/async-channel
         racket/tcp
         racket/unix-socket
         msgpack)

(provide start-client
         stop-client
         rpc-call
         rpc-notify)

;; Message encoders. See the msgpack-rpc spec for explanations of the data layout and magic numbers
;;; TODO Right now, these will fail if given non-Packable types
(define (make-request out-chan msgid method params)
  (let ([data (vector 0 msgid method (list->vector params))])
    (pack-to out-chan data)))

;;; We assume that the server only gives us good responses, which is almost certainly a terrible
;;; idea
(define (make-response-handler cust)
  (parameterize ([current-custodian cust])
                (let ([callback-channel (make-async-channel)])
                  (define (response-handler data)
                    (match data
                           [(vector 1 msgid err result) (async-channel-put callback-channel (list err result))]))
                  (values callback-channel response-handler))))

(define (make-notify out-chan method params)
  (let ([data (vector 2 method (list->vector params))])
    (pack-to out-chan data)))

;; Making a call
(define (rpc-call client method #:sync? [sync? #t] . args)
  (match sync?
         [#t (send client sync-call method args)]
         [#f (send client async-call method args)]))

(define (rpc-notify client method . args)
  (send client sync-notify method args))

;; Client management
(define (start-client addr [port-num null] [conn-type "unix"])
  (let ([client (new rpc-client% [address addr] [port-num port-num] [connection-type conn-type])])
    (send client start)
    client))

(define (stop-client client)
  (send client stop))

;; The RPC Client class
;;; TODO All methods that require the client to be started should check that it has been started
;;; TODO Error checking & exceptions
;;; TODO Thread safety
(define rpc-client%
  (class object%
         (init-field address [port-num null] [connection-type "unix"])
         (super-new)
         (define next-id-num 0)
         (define loop null)
         (define pending-requests (make-hash))
         (define client-cust (make-custodian))
         ;;; Initialized as null so that the custodian can manage them
         (define in null)
         (define out null)
         ;;; Generate next valid 32-bit integer msgid
         (define/private (next-id) (set! next-id-num (if (< next-id-num (sub1 (expt 2 32))) (add1 next-id-num) 0)))
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
                                   (let callback-loop ()
                                     (sync (handle-evt in
                                                       ;;; We assume that the client only ever gets responses back. This is
                                                       ;;; maybe a bad assumption
                                                       (lambda (evt) (dispatch-response (unpack-from evt)))))
                                     (callback-loop)))))))
         (define/private (dispatch-response data)
           ((hash-ref pending-requests (vector-ref data 1)) data))
         (define/private (send-request method args)
           (let-values ([(callback-channel callback-handler) (make-response-handler client-cust)])
             (hash-set! pending-requests next-id-num callback-handler)
             (make-request out next-id-num method args)
             (flush-output out)
             (next-id)
             callback-channel))
         (define/public (sync-call method args)
           (let ([callback-channel (send-request method args)])
             (async-channel-get callback-channel)))
         (define/public (async-call method args)
           (let ([callback-channel (send-request method args)])
             callback-channel))
         (define/public (sync-notify method args)
           (make-notify out method args)
           (flush-output out))))
