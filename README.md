# keel

**English** · [中文](README.zh-CN.md)

[![CI](https://github.com/turlamai/keel/actions/workflows/ci.yml/badge.svg)](https://github.com/turlamai/keel/actions/workflows/ci.yml) ![Racket](https://img.shields.io/badge/Racket-9.0%20%7C%209.3-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE) [![Version](https://img.shields.io/github/v/release/turlamai/keel?label=version)](https://github.com/turlamai/keel/releases/latest)

`keel` is the transport-neutral application contract shared by
Racket desktop runtimes. It gives native-rendered and WebView-rendered stacks
one small value model, one canonical byte encoding, one structured-error shape,
one lifecycle vocabulary, one transport-neutral schema vocabulary, and one
compatibility corpus. The contract homepage is
[keel.jrtx.site](https://keel.jrtx.site/).

The package intentionally does **not** own UI controls, transport frames,
process embedding, HTTP, WebView messaging, or platform policy. Rivet keeps
RVT1 and its WinUI 3 / SwiftUI-AppKit / GTK4 hosts; Glaze keeps GLZ1 and its
native WebView adapters.

Permit and Commerce are deliberately outside this dependency chain. Products
may compose [Permit](https://github.com/turlamai/permit) beside Rivet or Glaze
for signed commercial rights and add
[Commerce](https://github.com/turlamai/commerce) when they need online sales
orchestration. Permit does not depend on Keel or either framework; Commerce's
headless core does not use Keel. The canonical five-repository graph,
ownership rules, and release order live in the
[family architecture](docs/family-architecture.md). The sibling runtimes are
[Rivet](https://github.com/turlamai/rivet) and
[Glaze](https://github.com/turlamai/glaze).

## Start here

Use Keel for transport-neutral values, canonical bytes, schemas and structured errors shared by runtimes. Most product developers should start with Rivet or Glaze rather than assemble a second application framework around Keel.

[Fit, maturity, upgrades and support](docs/USING.md) · [简体中文](docs/USING.zh-CN.md)

## Quick Start

The package is published on the official Racket package catalog (see
[its install status](#published-package-install-status) for the verification
state):

```sh
raco pkg install --auto keel
```

To install straight from this repository instead:

```sh
raco pkg install --auto --name keel https://github.com/turlamai/keel.git
```

Then values round-trip through one canonical encoding:

```racket
#lang racket/base

(require keel)

(define wire
  (encode-app-value (hash "task" "review" "progress" 0.5)))

(decode-app-value wire)
```

Schemas, structured errors, and the lifecycle vocabulary are introduced under
[Contract v1](#contract-v1); the full binding reference lives in the Scribble
manual (`raco docs keel`).

## Contract v1

The value union is:

- Null, Bool, signed Int64, finite Float64, UTF-8 String, Bytes
- List and immutable Map with String keys
- structured Error: kebab-case code, human-safe message, optional data value

Encoding is canonical. Existing RVT1 scalar/list tags remain byte-identical;
Float64, Map, and Error append new tags. Map keys are ordered by their UTF-8
bytes, non-finite floats are rejected, duplicate/non-canonical keys are rejected
on decode, and every implementation enforces the same 64 MiB, depth-64, and
262,144-node budgets. See [the normative contract](docs/contract-v1.md).

```racket
#lang racket/base

(require keel)

(define payload
  (hash "task" "review"
        "progress" 0.5
        "tags" (list "racket" "desktop")))

(define wire (encode-app-value payload))
(decode-app-value wire)

(make-app-error "invalid-args" "Expected a non-empty title"
                (hash "field" "title"))
```

Schemas describe the application boundary without prescribing its transport:

```racket
(define Task
  (schema-record 'Task
                 (list (schema-field 'id Int64)
                       (schema-field 'title String))))

(define task-schema
  (make-app-schema
   "org.racket.taskboard" 1
   #:records (list Task)
   #:commands
   (list (schema-command 'create-task
                         (list (schema-parameter 'title String))
                         (reference-type 'Task)
                         '("invalid-args")))))

(encode-app-schema task-schema)
```

Rivet may map a command to an RVT1 RPC while Glaze maps it to a GLZ1 invoke;
the schema does not own either envelope. Schema names preserve ordinary Racket
conventions such as `ready?`, `save!`, and `string->bytes`, plus Unicode;
consumer code generators own collision-checked source-language identifiers.

## Compatibility discipline

`keel-test/golden-v1.txt` is the normative byte corpus. Changing an existing line
is a compatibility break. New union members require a written rationale, new
cross-runtime golden vectors, decoder budget tests, and a version decision.
Transport protocols may embed this codec, but they must negotiate their own
versions and error taxonomies.

## Published package install status

The [official Racket package catalog](https://pkgs.racket-lang.org/package/keel)
was corrected to `https://github.com/turlamai/keel.git#main` on
2026-10-29. The package page links the current official build transcript;
treat that transcript as authoritative rather than a test count copied here.
The [catalog release gate](docs/package-catalog-release.md) guards against
regressions; [issue #8](https://github.com/turlamai/keel/issues/8)
tracks the separate Rivet/Glaze downstream rerun evidence.

## Development

```sh
raco pkg install --auto --name keel --link
raco test -p keel
raco setup --doc-index --check-pkg-deps --pkgs keel
```

The package is tested on Racket CS 9.0 and 9.3 and is MIT licensed.

Compatibility changes follow the review gates in
[CONTRIBUTING.md](CONTRIBUTING.md). Please report suspected vulnerabilities
through the private process in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE).
