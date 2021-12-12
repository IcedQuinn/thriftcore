
Thrift Core

This repository provides low level components like zigzag encoding,
encoding and decoding of variable length integers,
encoding and decoding headings,
common and simple headers for layered transports.

Has support for the
[compact protocol](https://github.com/apache/thrift/blob/master/doc/specs/thrift-compact-protocol.md)
and the
[THeader protocol from fbthrift](https://github.com/apache/thrift/blob/master/doc/specs/HeaderFormat.md).

# Usage

# Restrictions
 - This repository provides only primitives for encoding and decoding.
   It does not provide an IDL parser and code generator.
 - It also does not provide transports to actually carry and execute RPC calls for you.

# Todo
 - Macro-based IDL generator?
 - Transport protocols?
 - Twitter Mux support?
 - Original, non-compact format?
 - JSON-RPC format?

# License
 - MPL 2.0

