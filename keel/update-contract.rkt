#lang racket/base

(require racket/list "semver.rkt")

;; Pure predicates for a future common update contract. These do not decode
;; legacy manifests, establish trust, select channels, or authorize installs.
(provide update-version-range?
         update-artifact-sha256?
         update-artifact-size?
         update-artifact-identity?
         unique-update-artifact-identities?)

(define (update-version-range? version minimum previous)
  (and (semver? version)
       (semver? minimum)
       (semver<? minimum version)
       (or (not previous)
           (and (semver? previous) (semver<? previous version)))))

(define (update-artifact-sha256? value)
  (and (string? value)
       (= (string-length value) 64)
       (regexp-match? #px"^[0-9A-Fa-f]{64}$" value)))

(define (update-artifact-size? value)
  (exact-positive-integer? value))

(define (identity-part? value)
  (and (string? value) (positive? (string-length value))))

;; All identity components are wire strings, not interned symbols.
;; A missing component is distinct from every named component.
(define (update-artifact-identity? value)
  (and (list? value)
       (= (length value) 4)
       (andmap identity-part? (take value 3))
       (or (not (fourth value)) (identity-part? (fourth value)))))

(define (unique-update-artifact-identities? values)
  (and (list? values)
       (pair? values)
       (andmap update-artifact-identity? values)
       (not (check-duplicates values equal?))))
