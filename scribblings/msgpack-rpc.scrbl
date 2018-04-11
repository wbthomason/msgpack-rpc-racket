#lang scribble/manual
@(require scribble/example (for-label msgpack-rpc msgpack racket))

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
@(examples
  #:label '()
  (start-client "127.0.0.1" 5781 "tcp"))
@subsection[#:tag "client-shutdown"]{Client Shutdown}
@subsection[#:tag "sync-call"]{Synchronous Calls}
@subsection[#:tag "async-call"]{Asynchronous Calls}
@subsection[#:tag "notify"]{Notifications}

@section{API}

@defproc[(start-client [addr string?] [

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
