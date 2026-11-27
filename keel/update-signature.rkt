#lang racket/base
(require "value.rkt" "update-manifest-codec.rkt" "update-manifest.rkt")
(provide (struct-out update-signature-envelope)
         update-signature-input
         encode-update-signature-envelope
         decode-update-signature-envelope
         verify-update-signature-envelope)

;; The signing domain and key ID are authenticated along with the exact payload.
;; The external verifier owns key lookup, trust scope and Ed25519 implementation.
(define domain "keel-update-manifest-signature/1")
(define (key-id? x)
  (and (string? x) (<= 1 (string-length x) 128)
       (regexp-match? #px"^[A-Za-z0-9._-]+$" x)
       (not (regexp-match? #rx"[\r\n]" x))))
(define (payload? x)
  (and (bytes? x) (<= 1 (bytes-length x) max-encoded-value-size)))
(struct update-signature-envelope (key-id payload signature)
  #:transparent
  #:guard
  (lambda (key-id payload signature who)
    (unless (key-id? key-id)
      (raise-argument-error who "bounded ASCII key ID" key-id))
    (unless (payload? payload)
      (raise-argument-error who "nonempty bounded bytes" payload))
    (unless (and (bytes? signature) (= (bytes-length signature) 64))
      (raise-argument-error who "64-byte Ed25519 signature" signature))
    (values (string->immutable-string key-id)
            (bytes->immutable-bytes payload)
            (bytes->immutable-bytes signature))))

(define (update-signature-input key-id payload)
  (unless (key-id? key-id)
    (raise-argument-error 'update-signature-input "bounded ASCII key ID" key-id))
  (unless (payload? payload)
    (raise-argument-error 'update-signature-input "nonempty bounded bytes" payload))
  (bytes->immutable-bytes
   (encode-app-value (list domain "ed25519" key-id payload))))

(define (encode-update-signature-envelope e)
  (unless (update-signature-envelope? e)
    (raise-argument-error 'encode-update-signature-envelope "update-signature-envelope?" e))
  (encode-app-value
   (hash "format" domain "algorithm" "ed25519"
         "key_id" (update-signature-envelope-key-id e)
         "payload" (update-signature-envelope-payload e)
         "signature" (update-signature-envelope-signature e))))

(define (decode-update-signature-envelope raw)
  (define v (decode-app-value raw))
  (unless (and (hash? v) (= (hash-count v) 5)
               (andmap (lambda (k) (hash-has-key? v k))
                       '("format" "algorithm" "key_id" "payload" "signature"))
               (equal? (hash-ref v "format") domain)
               (equal? (hash-ref v "algorithm") "ed25519"))
    (error 'decode-update-signature-envelope "invalid envelope fields or format"))
  (update-signature-envelope (hash-ref v "key_id")
                             (hash-ref v "payload")
                             (hash-ref v "signature")))

(define (verify-update-signature-envelope e verifier)
  (unless (update-signature-envelope? e)
    (raise-argument-error 'verify-update-signature-envelope "update-signature-envelope?" e))
  (unless (and (procedure? verifier) (procedure-arity-includes? verifier 3))
    (raise-argument-error 'verify-update-signature-envelope "three-argument verifier" verifier))
  (define key-id (update-signature-envelope-key-id e))
  (define payload (update-signature-envelope-payload e))
  ;; Do not parse the manifest until the external verifier explicitly returns #t.
  (unless (eq? #t (verifier key-id (update-signature-input key-id payload)
                            (update-signature-envelope-signature e)))
    (error 'verify-update-signature-envelope "signature rejected"))
  (decode-update-manifest payload))
