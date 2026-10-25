#lang racket/base

(require rackunit
         "../keel/main.rkt")

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
