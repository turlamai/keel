#lang scribble/manual

@(require (for-label racket/base keel))

@title{Keel: Neutral Contracts for Racket Desktop Runtimes}

@defmodule[keel]

Keel defines a transport-neutral value codec, structured error shape,
schema vocabulary, and lifecycle vocabulary. It deliberately does not define
a renderer or protocol frame.

@section{Values}

@defthing[app-null void?]{The canonical Null value.}
@defproc[(app-null? [value any/c]) boolean?]{Recognizes Null.}
@defproc[(app-value? [value any/c]) boolean?]{Recognizes values encodable by v1.}
@defproc[(encode-app-value [value app-value?]) bytes?]{Encodes one canonical value.}
@defproc[(decode-app-value [encoded bytes?]) app-value?]{Decodes exactly one canonical value and rejects trailing bytes.}

@defthing[max-encoded-value-size exact-positive-integer?]{The 64 MiB byte budget.}
@defthing[max-value-depth exact-positive-integer?]{The maximum container nesting depth.}
@defthing[max-value-nodes exact-positive-integer?]{The aggregate value-node budget.}

@section{Structured errors}

@defproc[(app-error? [value any/c]) boolean?]{Recognizes a transport-neutral structured error.}
@defproc[(make-app-error [code app-error-code?]
                         [message string?]
                         [data app-value? app-null])
         app-error?]{Constructs a transport-neutral error value.}
@defproc[(app-error-code? [value any/c]) boolean?]{Recognizes portable kebab-case error tokens.}
@defproc[(app-error-code [error app-error?]) string?]{Returns the error code.}
@defproc[(app-error-message [error app-error?]) string?]{Returns the human-safe message.}
@defproc[(app-error-data [error app-error?]) app-value?]{Returns the structured data value.}

@section{Schemas}

A schema describes application messages without selecting their transport.
Rivet can map a command to an RVT1 RPC while Glaze maps it to a GLZ1 invoke.

@defstruct*[scalar-type ([name symbol?])]
@defstruct*[list-type ([element schema-type?])]
@defstruct*[map-type ([value schema-type?])]
@defstruct*[optional-type ([element schema-type?])]
@defstruct*[reference-type ([name string?])]

@defthing[Null scalar-type?]
@defthing[Bool scalar-type?]
@defthing[Int64 scalar-type?]
@defthing[Float64 scalar-type?]
@defthing[String scalar-type?]
@defthing[Bytes scalar-type?]
@defthing[Value scalar-type?]
@defthing[Error scalar-type?]
@defthing[Unit scalar-type?]

@defstruct*[schema-field ([name string?] [type schema-type?])]
@defstruct*[schema-record ([name string?] [fields (listof schema-field?)])]
@defstruct*[schema-enum ([name string?] [cases (listof string?)])]
@defstruct*[schema-parameter ([name string?] [type schema-type?])]
@defstruct*[schema-command ([name string?]
                            [parameters (listof schema-parameter?)]
                            [result schema-type?]
                            [error-codes (listof app-error-code?)])]
@defstruct*[schema-event ([name string?] [type schema-type?])]
@defstruct*[schema-state ([name string?] [type schema-type?])]

@defproc[(make-app-schema [id string?]
                          [revision exact-nonnegative-integer?]
                          [#:records records list? null]
                          [#:enums enums list? null]
                          [#:commands commands list? null]
                          [#:events events list? null]
                          [#:states states list? null])
         app-schema?]{Validates references, uniqueness, type placement, and names, then returns a canonical schema.}
@defproc[(app-schema? [value any/c]) boolean?]{Recognizes a validated application schema.}
@defproc[(app-schema-id [schema app-schema?]) string?]{Returns the schema identity.}
@defproc[(app-schema-revision [schema app-schema?]) exact-nonnegative-integer?]{Returns the schema revision.}
@defproc[(app-schema-records [schema app-schema?]) (listof schema-record?)]{Returns the records in canonical declaration order.}
@defproc[(app-schema-enums [schema app-schema?]) (listof schema-enum?)]{Returns the enums in canonical declaration order.}
@defproc[(app-schema-commands [schema app-schema?]) (listof schema-command?)]{Returns the commands in canonical declaration order.}
@defproc[(app-schema-events [schema app-schema?]) (listof schema-event?)]{Returns the events in canonical declaration order.}
@defproc[(app-schema-states [schema app-schema?]) (listof schema-state?)]{Returns the states in canonical declaration order.}
@defproc[(schema-type? [value any/c]) boolean?]{Recognizes scalar, list, map, optional, and named-reference type descriptors.}
@defproc[(schema-name? [value any/c]) boolean?]{Recognizes a non-empty schema identity of at most 255 UTF-8 bytes, excluding control, format, and surrogate code points. Names preserve Racket punctuation and Unicode; consumers map them to collision-checked local identifiers.}
@defproc[(schema-type->app-value [type schema-type?]) app-value?]{Returns the normative introspection value for one type descriptor.}
@defproc[(app-schema->app-value [schema app-schema?]) app-value?]{Returns the normative introspection value for schema contract 1.}
@defproc[(encode-app-schema [schema app-schema?]) bytes?]{Canonically encodes the introspection value.}

The scalar descriptors are @racket[Null], @racket[Bool], @racket[Int64],
@racket[Float64], @racket[String], @racket[Bytes], @racket[Value],
@racket[Error], and @racket[Unit]. Compound descriptors use
@racket[list-type], @racket[map-type], @racket[optional-type], and
@racket[reference-type]. Definitions use @racket[schema-field],
@racket[schema-record], @racket[schema-enum], @racket[schema-parameter],
@racket[schema-command], @racket[schema-event], and @racket[schema-state].

@section{Lifecycle}

@defthing[lifecycle-states (listof symbol?)]{The lifecycle vocabulary, in order: @racket['starting], @racket['ready], @racket['running], @racket['stopping], and @racket['stopped].}
@defthing[lifecycle-initial-state symbol?]{The state every shared runtime starts in: @racket['starting].}
@defproc[(lifecycle-state? [value any/c]) boolean?]{Recognizes @racket['starting], @racket['ready], @racket['running], @racket['stopping], and @racket['stopped].}
@defproc[(lifecycle-terminal-state? [value any/c]) boolean?]{Recognizes the terminal lifecycle state, @racket['stopped].}
@defproc[(lifecycle-transition? [from lifecycle-state?] [to lifecycle-state?]) boolean?]{Reports whether the transition is part of the shared lifecycle contract.}
@defthing[request-terminal-outcomes (listof symbol?)]{The mutually exclusive request outcomes: @racket['succeeded], @racket['failed], @racket['cancelled], and @racket['timed-out].}
@defproc[(request-terminal-outcome? [value any/c]) boolean?]{Recognizes the mutually exclusive request outcomes.}
