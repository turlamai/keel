#lang info

(define name "keel")
(define collection 'multi)
(define version "0.3.1")
(define pkg-desc "Transport-neutral application contracts for Racket desktop runtimes")
(define pkg-authors '(turlamai))
(define license 'MIT)

;; Tests ship inside this package (keel-test/), so rackunit is a runtime
;; dep — raco setup --check-pkg-deps classifies keel-test requires as
;; run-mode, and the glaze/foreman precedent declares it the same way.
(define deps '(["base" #:version "9.0"] "rackunit-lib"))
(define build-deps '("racket-doc" "scribble-lib"))

;; `site/` is the product website, not packaged library source (same
;; discipline as permit's source-omit-files).
(define source-omit-files
  '("site"))
