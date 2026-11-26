#lang racket/base

(require racket/list "update-contract.rkt")

(provide (struct-out update-artifact)
         (struct-out update-manifest)
         update-artifact-identity)

;; Immutable normalized values, not a wire encoding or authenticated result.
;; Consumers retain URL validation, signature verification and install policy.
(define (nonempty-string? x)
  (and (string? x) (positive? (string-length x))))
(define (freeze x) (string->immutable-string x))
(define (optional-freeze x) (and x (freeze x)))
(define (field who name pred value)
  (unless (pred value)
    (raise-arguments-error who "invalid update contract field" "field" name))
  value)

(struct update-artifact
  (platform architecture url sha256 size installer arguments component signature)
  #:transparent
  #:guard
  (lambda (platform architecture url sha256 size installer arguments component signature who)
    (field who 'identity update-artifact-identity?
           (list platform architecture installer component))
    (field who 'url nonempty-string? url)
    (field who 'sha256 update-artifact-sha256? sha256)
    (field who 'size update-artifact-size? size)
    (field who 'arguments (lambda (v) (and (list? v) (andmap string? v))) arguments)
    (field who 'signature (lambda (v) (or (not v) (nonempty-string? v))) signature)
    (values (freeze platform) (freeze architecture) (freeze url)
            (freeze (string-downcase sha256)) size (freeze installer)
            (map freeze arguments) (optional-freeze component)
            (optional-freeze signature))))

(define (update-artifact-identity artifact)
  (unless (update-artifact? artifact)
    (raise-argument-error 'update-artifact-identity "update-artifact?" artifact))
  (list (update-artifact-platform artifact)
        (update-artifact-architecture artifact)
        (update-artifact-installer artifact)
        (update-artifact-component artifact)))

(struct update-manifest
  (application-id version build channel published-at minimum-version
                  previous-version rollback-allowed? rollout artifacts)
  #:transparent
  #:guard
  (lambda (application-id version build channel published-at minimum-version
                          previous-version rollback-allowed? rollout artifacts who)
    (field who 'application-id nonempty-string? application-id)
    (field who 'versions
           (lambda (v) (apply update-version-range? v))
           (list version minimum-version previous-version))
    (field who 'build exact-positive-integer? build)
    (field who 'channel nonempty-string? channel)
    (field who 'published-at nonempty-string? published-at)
    (field who 'rollback-allowed? boolean? rollback-allowed?)
    (field who 'rollout (lambda (v) (and (exact-integer? v) (<= 0 v 100))) rollout)
    (field who 'artifacts
           (lambda (v)
             (and (list? v)
                  (andmap update-artifact? v)
                  (unique-update-artifact-identities? (map update-artifact-identity v))))
           artifacts)
    (values (freeze application-id) (freeze version) build (freeze channel)
            (freeze published-at) (freeze minimum-version)
            (optional-freeze previous-version) rollback-allowed? rollout artifacts)))
