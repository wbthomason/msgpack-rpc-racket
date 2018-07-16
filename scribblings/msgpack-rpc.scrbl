#lang scribble/manual
@(require scribble/example (for-label racket msgpack-rpc msgpack))

@title{MessagePack-RPC Client for Racket}
@author[@author+email["Wil Thomason" "wbthomason@cs.cornell.edu"]]

@defmodule[msgpack-rpc]

This package implements a RPC client in accordance with the
@hyperlink["https://github.com/msgpack-rpc/msgpack-rpc/blob/master/spec.md"]{MessagePack-RPC spec}.
It supports calls (@seclink["async-call"]{asynchronous} and @seclink["sync-call"]{synchronous}) and
@seclink["notify"]{notifications}, and can use TCP and UNIX domain sockets as transports.

The source is at: @url["https://github.com/wbthomason/msgpack-rpc-racket"]

PRs and issues are welcome!

@table-of-contents[]

@section{Introduction}

@hyperlink["https://github.com/msgpack-rpc/msgpack-rpc"]{MessagePack-RPC} is a simple, efficient
@hyperlink["https://en.wikipedia.org/wiki/Remote_procedure_call"]{RPC} protocol using the
@hyperlink["https://msgpack.org"]{MessagePack} serialization library.

This package implements a client for the MessagePack-RPC protocol in Racket.

@section{Usage}

The basic usage flow for the library is: Create a client connected to some MessagePack-RPC server.
Perform a sequence of calls using the client. Shut down the client. Below are examples of these
operations.

@subsection[#:tag "client-create"]{Client Creation}
Here we show how to connect using TCP to a server running at port 5781 on localhost.
@(racketblock (define client (start-client "127.0.0.1" 5781 "tcp")))

@subsection[#:tag "sync-call"]{Synchronous Calls}
Next, we'll make a synchronous call to a method named @racket["plusone"] with the argument
@racket[4], and check the result.
@(racketblock (match-let ([(list err result) (rpc-call client "plusone" 4)])
                         (if (not (void? err))
                             (printf "Got error: ~a\n" err)
                             (printf "Got result: ~a\n" result))))

@subsection[#:tag "async-call"]{Asynchronous Calls}
Now we'll make the same call, but asynchronously.
@(racketblock
  (define chan (rpc-call client "plusone" 4 #:sync? #f))
  (match-let ([(list err result) (async-channel-get chan)])
                         (if (not (void? err))
                             (printf "Got error: ~a\n" err)
                             (printf "Got result: ~a\n" result))))

@subsection[#:tag "notify"]{Notifications}
Next, we'll send a notification to the method @racket["sayhi"] with an argument
@racket["Racket"].
@(racketblock (rpc-notify client "sayhi" "Racket"))

@subsection[#:tag "client-shutdown"]{Client Shutdown}
And, finally, we'll shut down the client we've been using.
@(racketblock (stop-client client))

@section{API}

@defproc[(start-client [addr string?] [port-num exact-positive-integer? null] [conn-type string?
"unix"]) (class?)]{Constructs a client and opens a connection to the
specified RPC server.}

@defproc[(stop-client [client (is-a? rpc-client%)]) any]{Stops a client's event loop and closes
its connection.}

@defproc[(rpc-call [client (is-a? rpc-client%)] [method string?] [#:sync? boolean? #t] [args any]
...) any]{Make a call to the method specified by @racket[method] on the RPC server @racket[client]
is connected to, with the arguments given in @racket[args]. If @racket[#:sync] is @racket[#t], block
until the call returns, then return @racket[(list err result)], reporting any errors in the call and the
result, if any, of the call. If @racket[#:sync] is @racket[#f], do not block, and immediately return
the @racket[async-channel] which will contain the call results in the same @racket[(list err result)]
format as before when the call returns.}

@defproc[(rpc-notify [client (is-a? rpc-client%)] [method string?] [args any]
...) any]{Send a notification to the method specified by @racket[method] on the RPC server
@racket[client] is connected to, with the arguments given in @racket[args]. A notification is
essentially a call that expects no result in return.}

@section{Warnings}

This package has been tested manually and verified to work. I have not yet
written unit tests, or any sort of formal tests, so caveat emptor. There are
also quite likely code smells and non-idiomatic Racket usages; this is the
first significant Racket I've written.

All that said, this works as expected in my uses of it, and I didn't find an
alternative when I searched.

@section{Thanks/Credits}

This module uses the (excellent) @racket[msgpack] library by
@hyperlink["https://gitlab.com/HiPhish"]{HiPhish}. After I wrote this module, I discovered HiPhish's
RPC implementation in @hyperlink["https://gitlab.com/HiPhish/neovim.rkt"]{his Racket Neovim client};
however, this module is less specialized to use with Neovim, uses a different client model and API
design, and is designed for general-purpose standalone @code{msgpack-rpc} use. 
