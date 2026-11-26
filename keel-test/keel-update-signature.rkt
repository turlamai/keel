#lang racket/base
(require rackunit keel/value keel/update-manifest keel/update-manifest-codec
         keel/update-signature)

(define manifest
  (update-manifest "example" "2.0.0" 2 "stable" "2026-11-26T00:00:00Z"
                   "1.0.0" #f #f 100
                   (list (update-artifact "linux" "x64" "https://example.test/a"
                                          (make-string 64 #\a) 1 "zip" '() #f #f))))
(define payload (encode-update-manifest manifest))
;; Synthetic test signature: NOT a cryptographic implementation.
(define sig (make-bytes 64 42))
(define e (update-signature-envelope "test-key" payload sig))
(define expected (update-signature-input "test-key" payload))
(define (fixture-verifier key input signature)
  (and (equal? key "test-key") (bytes=? input expected) (bytes=? signature sig)))

(test-case "exact signature domain and envelope round trip"
  (check-equal? (decode-app-value expected)
                (list "keel-update-manifest-signature/1" "ed25519" "test-key" payload))
  (check-not-equal? expected payload)
  (check-not-equal? expected (update-signature-input "other-key" payload))
  (check-equal? (decode-update-signature-envelope (encode-update-signature-envelope e)) e)
  (check-equal? (verify-update-signature-envelope e fixture-verifier) manifest))

(test-case "rejection precedes manifest parsing"
  (define malformed (update-signature-envelope "test-key" #"invalid" sig))
  (define called? #f)
  (check-exn #rx"signature rejected"
             (lambda ()
               (verify-update-signature-envelope malformed
                 (lambda (key input signature) (set! called? #t) #f))))
  (check-true called?)
  (check-exn exn:fail? (lambda () (verify-update-signature-envelope malformed
                                                                   (lambda args #t))))
  (check-exn #rx"signature rejected" (lambda () (verify-update-signature-envelope e
                                                                                 (lambda args 'yes))))
  (for ([changed (in-list (list (update-signature-envelope "other-key" payload sig)
                                (update-signature-envelope "test-key" #"changed" sig)
                                (update-signature-envelope "test-key" payload (make-bytes 64 0))))])
    (check-exn #rx"signature rejected"
               (lambda () (verify-update-signature-envelope changed fixture-verifier)))))

(test-case "closed envelope and immutable snapshots"
  (define raw (encode-update-signature-envelope e))
  (define v (decode-app-value raw))
  (for ([bad (in-list (list (hash-set v "algorithm" "none")
                            (hash-set v "extra" #t)
                            (hash-remove v "key_id")
                            (hash-set v "signature" (make-bytes 63))
                            (hash-set v "key_id" "bad\n")))])
    (check-exn exn:fail? (lambda () (decode-update-signature-envelope (encode-app-value bad)))))
  (define mutable (bytes-copy sig))
  (define snapshot (update-signature-envelope "test-key" payload mutable))
  (bytes-set! mutable 0 0)
  (check-equal? (update-signature-envelope-signature snapshot) sig)
  (check-true (immutable? (update-signature-envelope-signature snapshot))))
