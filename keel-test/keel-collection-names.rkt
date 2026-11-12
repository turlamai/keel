#lang racket/base

;; Collection-name guard. The top-level `tests` collection is shared by
;; every package in an installation: a module path such as `tests/error`
;; is claimed globally, and two packages providing the same module path
;; cannot coexist (raco pkg install conflict). An unprefixed Keel test
;; module once collided with rivet v0.11.0's `tests/documentation` and
;; broke every downstream install (issue #5), so Keel requires the
;; `keel-` prefix on every module it ships in `tests/`. This test keeps
;; the rule from eroding.

(require rackunit
         racket/file
         racket/list
         racket/runtime-path
         racket/path
         racket/string)

(define-runtime-path tests-directory ".")

(define test-modules
  (filter (lambda (path) (equal? (path-get-extension path) #".rkt"))
          (directory-list tests-directory)))

(for ([module-path test-modules])
  (define name (path->string (file-name-from-path module-path)))
  (check-true
   (string-prefix? name "keel-")
   (format "tests/~a must start with keel-: `tests` is a collection shared by every installed package"
           name)))
