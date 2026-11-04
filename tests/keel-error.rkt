#lang racket/base

(require rackunit
         "../keel/main.rkt"
         (submod "../keel/error.rkt" private))

(for ([code (in-list '("invalid-args" "timeout" "capability-denied" "e2"))])
  (check-true (app-error-code? code)))

(for ([code (in-list '("" "Invalid" "bad_code" "-bad" "bad-" "two words"))])
  (check-false (app-error-code? code))
  (check-exn exn:fail? (lambda () (make-app-error code "message"))))

(define failure (make-app-error "invalid-args" "Expected a String" (hash "field" "name")))
(check-equal? (app-error-code failure) "invalid-args")
(check-equal? (app-error-message failure) "Expected a String")
(check-equal? (app-error-data failure) (hash "field" "name"))

(check-exn exn:fail:contract?
           (lambda () (make-app-error "invalid-args" "message" #\x)))

;; The private constructor is reachable via `(submod keel/error private)`, so
;; the struct guard must enforce the shape even on that path. Otherwise a user
;; could mint an `app-error?` value with a non-portable code or a non-string
;; message and break the predicate's documented invariant.
(check-exn exn:fail:contract?
           (lambda () (make-unchecked-app-error "Not A Code" "message" (void))))
(check-exn exn:fail:contract?
           (lambda () (make-unchecked-app-error "valid-code" 42 (void))))
