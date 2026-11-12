# Keel first round trip

**English** · [简体中文](getting-started.zh-CN.md)

Requires Racket 9.0+. Install the catalog package instead of copying its source:

```sh
raco pkg install --auto keel
```

Save as roundtrip.rkt:

```racket
#lang racket/base
(require keel)
(define original (hash "task" "review" "done" #f))
(define encoded (encode-app-value original))
(unless (equal? original (decode-app-value encoded))
  (error 'roundtrip "round trip failed"))
(displayln "Keel round trip passed")
```

```sh
racket roundtrip.rkt
```

Expected output: `Keel round trip passed`. This checks one local public-API round trip, not other languages, versions or network transports.

Keel supplies no RPC envelope, network endpoint or UI. A consuming framework maps schemas to its own transport; preserve normative rejection rules, canonical map ordering and budgets.

Continue with the [v1 contract](contract-v1.md), [adoption/support](USING.md) and [CONTRIBUTING](../CONTRIBUTING.md). Independent implementations execute the normative `keel-test/golden-v1.txt` corpus.
