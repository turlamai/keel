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

;; Independent known-answer fixture: Python cryptography / Ed25519,
;; public RFC 8032 TEST 1 seed. Never a production key.
(define (hex->bytes s)
  (list->bytes (for/list ([i (in-range 0 (string-length s) 2)])
                 (string->number (substring s i (+ i 2)) 16))))
(define golden-input
  (hex->bytes
   (string-append
    "060400000004200000006b65656c2d7570646174652d6d616e69666573742d7369676e61747572652f31040700000065"
    "6432353531390408000000746573742d6b65790527020000080b000000040e0000006170706c69636174696f6e5f6964"
    "04070000006578616d706c65040900000061727469666163747306010000000809000000040c00000061726368697465"
    "637475726504030000007836340409000000617267756d656e747306000000000409000000636f6d706f6e656e740104"
    "09000000696e7374616c6c657204030000007a69700408000000706c6174666f726d04050000006c696e757804060000"
    "007368613235360440000000616161616161616161616161616161616161616161616161616161616161616161616161"
    "6161616161616161616161616161616161616161616161616161616104090000007369676e6174757265010404000000"
    "73697a65030100000000000000040300000075726c041600000068747470733a2f2f6578616d706c652e746573742f61"
    "04050000006275696c6403020000000000000004070000006368616e6e656c0406000000737461626c65040600000066"
    "6f726d617404160000006b65656c2d7570646174652d6d616e69666573742f31040f0000006d696e696d756d5f766572"
    "73696f6e0405000000312e302e30041000000070726576696f75735f76657273696f6e01040c0000007075626c697368"
    "65645f61740414000000323032362d31312d32365430303a30303a30305a0410000000726f6c6c6261636b5f616c6c6f"
    "776564010407000000726f6c6c6f7574036400000000000000040700000076657273696f6e0405000000322e302e30")))
(define golden-signature (hex->bytes "1406d594d05d954d9b385ab814a85fc90f401a835ab0abb927ebe0a86fbcf1dd867a4ee9893931ed9cc7d22d3c5aa47eb5e8aa29258c9ed0efc7c8bc4bb48d04"))
(define golden-public-key (hex->bytes "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a"))

(test-case "independent Ed25519 signing input known-answer bytes"
  (check-equal? expected golden-input)
  (check-equal? (bytes-length golden-signature) 64)
  (check-equal? (bytes-length golden-public-key) 32)
  (define signed (update-signature-envelope "test-key" payload golden-signature))
  (check-equal? (decode-update-signature-envelope
                 (encode-update-signature-envelope signed)) signed))
