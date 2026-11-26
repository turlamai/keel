#lang racket/base
(require rackunit keel/value keel/update-manifest keel/update-manifest-codec)
(define a (update-artifact "linux" "x64" "https://example.test/a"
                           (make-string 64 #\a) 100 "zip" '("--quiet") "app" "sig"))
(define m (update-manifest "example" "2.0.0" 2 "stable" "2026-11-26T00:00:00Z"
                           "1.0.0" #f #f 100 (list a)))
(define raw (encode-update-manifest m))
(define v (decode-app-value raw))
(test-case "canonical round trip"
  (check-equal? (decode-update-manifest raw) m)
  (check-equal? (encode-update-manifest (decode-update-manifest raw)) raw)
  (check-equal? (hash-ref v "format") "keel-update-manifest/1"))
(test-case "reject malformed and unsupported payloads"
  (for ([bad (in-list (list (hash-set v "format" "unknown")
                            (hash-set v "extra" #t)
                            (hash-remove v "version")
                            (hash-set v "artifacts" '())
                            (hash-set v "build" 0)
                            (hash-set v "artifacts" (append (hash-ref v "artifacts") (hash-ref v "artifacts")))
                            (hash-set v "artifacts" (list (hash-set (car (hash-ref v "artifacts")) "sha256" (make-string 64 #\A))))))])
    (check-exn exn:fail? (lambda () (decode-update-manifest (encode-app-value bad)))))
  (check-exn exn:fail? (lambda () (decode-update-manifest (bytes-append raw #"x"))))
  (check-exn exn:fail? (lambda () (decode-update-manifest (subbytes raw 0 (sub1 (bytes-length raw)))))))
