#lang info
(define collection "msgpack-rpc")
(define deps '("base" "msgpack" "unix-socket-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/msgpack-rpc.scrbl" ())))
(define pkg-desc "MsgPack RPC Client in Racket")
(define version "0.1.1")
(define pkg-authors '(wbthomason))
