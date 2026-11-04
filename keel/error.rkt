#lang racket/base

(provide app-error?
         app-error-code
         app-error-message
         app-error-data
         app-error-code?)

;; Error codes are transport-neutral kebab-case tokens. Each protocol owns its
;; closed taxonomy; the shared value layer only guarantees a portable shape.
(define error-code-rx #px"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")

(define (app-error-code? value)
  (and (string? value) (regexp-match-exact? error-code-rx value) #t))

;; The guard enforces the two shape invariants this module can check without
;; creating a module cycle: a portable code token and a string message. Error
;; data is validated by the value layer before it calls this constructor.
;; Keeping the guard on the struct (rather than only on `make-app-error`) also
;; protects the private constructor exported below: requiring
;; `(submod keel/error private)` cannot mint an `app-error?` value whose code or
;; message violates the documented shape.
(struct app-error (code message data)
  #:transparent
  #:constructor-name make-unchecked-app-error
  #:guard
  (lambda (code message data who)
    (unless (app-error-code? code)
      (raise-arguments-error who
                             "expected a portable kebab-case error code"
                             "code"
                             code))
    (unless (string? message)
      (raise-arguments-error who "expected a string message" "message" message))
    (values code message data)))

;; The value layer still owns error-data validation; it needs this constructor
;; to avoid a cycle between error.rkt and value.rkt.
(module* private #f
  (provide make-unchecked-app-error))
