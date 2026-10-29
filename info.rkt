#lang info

(define name "keel")
(define collection 'multi)
(define version "0.3.1")
(define pkg-desc "Transport-neutral application contracts for Racket desktop runtimes")
(define pkg-authors '(turlamai))
(define license 'MIT)

(define deps '(["base" #:version "9.0"]))
(define build-deps '("racket-doc" "rackunit-lib" "scribble-lib"))
