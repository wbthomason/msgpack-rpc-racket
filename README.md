# msgpack-rpc

A `msgpack-rpc` client in Racket.

## How to use

See [the Racket library docs](https://docs.racket-lang.org/msgpack-rpc/index.html) for usage
examples and API documentation.

## Caveats/Status

This module contains a manually-tested working `msgpack-rpc` client. It has not been sufficiently
tested. It is also the first thing I've ever written in Racket, so it's probably at least bad in
style, maybe buggy. It may not work. It may unexpectedly not work. It may eat your lunch, computer,
and dog. PRs to improve are welcome; I plan to add tests and features to the module as I have time,
but this will probably happen slowly.

I have not yet written a `msgpack-rpc` server in this module, but I plan to.

This module does not use Typed Racket. There's not a great reason for this other than (maybe? is
this a true thing to believe?) avoiding slowdowns between this library and untyped libraries that
want to use it.

## Thanks/Credits

This module uses the (excellent) [`msgpack` library](https://gitlab.com/HiPhish/MsgPack.rkt) by
@HiPhish. After I wrote this module, I discovered the @HiPhish's RPC implementation in [his Racket
Neovim client](https://gitlab.com/HiPhish/neovim.rkt/); however, this module structures things a bit
differently and takes a different approach (multiple clients, clients as classes, simplified API,
etc.), and is also designed for general standalone `msgpack-rpc` use.
