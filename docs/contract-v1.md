# Keel Contract v1

This document is normative for the version-1 value, schema, and lifecycle contracts.
The Racket implementation and `keel-test/golden-v1.txt` are executable evidence.

## Scope

Keel sits above a byte stream and below an application protocol. It owns
values, errors, lifecycle names, cancellation terminality, canonical encoding,
and resource limits. It does not own a frame header, request identifier,
streaming/backpressure mechanism, renderer, permission model, or installer.

## Canonical values

All integer fields are little-endian. Lengths and collection counts are
unsigned 32-bit values. Values use one byte tag followed by the listed body.

| Tag | Value | Body |
|---:|---|---|
| `00` | Null | none |
| `01` | False | none |
| `02` | True | none |
| `03` | Int64 | signed two's-complement 64-bit integer |
| `04` | String | byte length + well-formed UTF-8 |
| `05` | Bytes | byte length + uninterpreted bytes |
| `06` | List | item count + encoded values |
| `07` | Float64 | finite IEEE-754 binary64 bits |
| `08` | Map | entry count + String key/value pairs |
| `09` | Error | String code + String message + data value |

Map keys are ordered by their encoded UTF-8 bytes in strictly increasing
lexicographic order. A decoder rejects duplicates and any other order. Map
keys are encoded as ordinary String values and count toward node/depth budgets.
Keys are also compared by string value on the value side: an eq-based hash
holding two distinct key objects with equal contents is not a canonical map
and is rejected before encoding.

Float64 preserves finite IEEE-754 bits, including the sign of zero. NaN and
positive/negative infinity are not values in v1 because JSON transports cannot
round-trip them portably.

Error codes match `[a-z][a-z0-9]*(-[a-z0-9]+)*`. Keel does not define a
closed list: RVT1, GLZ1, and future transports each publish and negotiate their
own taxonomy. Error messages are safe for users and logs; protocols must not
substitute raw exception text. Error data may be any Keel value.

## Budgets and rejection

- maximum encoded value: 64 MiB
- maximum container nesting: 64
- maximum decoded/encoded value nodes: 262,144

Decoders reject unknown tags, malformed/truncated lengths, invalid UTF-8,
non-finite Float64, non-String Map keys, non-canonical Map order, invalid Error
shapes, budget overflow, and trailing bytes. Encoders reject mutable maps,
improper/cyclic lists, unsupported values, and the same budget violations.

## Lifecycle

The shared vocabulary is `starting -> ready -> running -> stopping -> stopped`.
Early shutdown may move `starting` or `ready` directly to `stopping`. `stopped`
is terminal; restart policy belongs to the embedding runtime.

For accepted requests, success, failure, cancellation, and timeout are mutually
exclusive terminal outcomes. Cancellation is an intent that races completion;
the winner owns the single terminal result, and later attempts are no-ops.

## Schema descriptors

The schema vocabulary is transport-neutral. It describes named records and
enums plus commands, events, and observable states. A command is the shared
application concept; a consumer may expose it as an RVT1 RPC, a GLZ1 invoke,
or another negotiated transport operation.

Types are Null, Bool, Int64, Float64, String, Bytes, Value, Error, Unit,
List, String-key Map, Optional, and references to named records or enums.
Unit is valid only as a command result. Every reference must resolve within
the same schema, and names are unique within their namespace. Record-field,
command-parameter, and enum-case order is semantic and preserved. Collections
of named definitions and endpoints are sorted by name for canonical encoding.

Schema names are non-empty Unicode strings whose UTF-8 representation is at
most 255 bytes. Control, format, and surrogate code points are rejected. A
name is a transport identity rather than a source-language identifier, so
Racket conventions such as `ready?`, `save!`, and `string->bytes` remain exact;
each code generator maps names to collision-checked local identifiers.

`app-schema->app-value` is the normative introspection shape. Its result is an
ordinary Keel value, and `encode-app-schema` applies the value codec above.
The top-level `contract` field is `1`; consumers must reject unsupported
contract numbers rather than guessing.

## Evolution

Existing tags and golden bytes never change within v1. An additive tag still
requires protocol negotiation because an older decoder must reject it. Any
change to numeric representation, canonical ordering, budgets, or structured
error shape requires a new Keel contract version and migration evidence.

Schema compatibility is separate from wire versioning. `app-schema-changes`
compares two revisions and classifies each difference as `breaking` or
`compatible`. Adding a record, enum, command, event, or state is compatible;
adding an optional record field is compatible. Removing any named definition,
adding a required record field or command parameter, adding a case to a closed
enum, adding or removing a declared command error code, or changing any type or
command result is breaking. The schema identity is part of the contract;
revision numbers are opaque and are not interpreted by the comparison.
