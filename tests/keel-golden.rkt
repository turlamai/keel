#lang racket/base

(require file/sha1
         rackunit
         racket/list
         racket/match
         racket/runtime-path
         racket/string
         "../keel/main.rkt")

(define-runtime-path corpus-path "golden-v1.txt")

(define fixtures
  (hash "null" app-null
        "false" #f
        "true" #t
        "int64-42" 42
        "int64-negative-one" -1
        "string-racket" "Racket"
        "bytes-sample" #"\0\377\20"
        "list-sample" (list #t "x")
        "float64-one-and-half" 1.5
        "map-sorted" (hash "b" #f "a" 1)
        "structured-error" (make-app-error "invalid-args" "bad")))

(define records
  (call-with-input-file corpus-path
    (lambda (input)
      (for/list ([line (in-lines input)]
                 #:unless (or (string=? line "") (string-prefix? line "#")))
        (match (string-split line "|")
          [(list name hex) (cons name (hex-string->bytes hex))]
          [_ (error 'golden "invalid corpus line: ~a" line)])))))

(check-equal? (length records) (hash-count fixtures))
(for ([record (in-list records)])
  (define name (car record))
  (define encoded (cdr record))
  (define expected (hash-ref fixtures name))
  (check-equal? (encode-app-value expected) encoded name)
  (check-equal? (encode-app-value (decode-app-value encoded)) encoded name)
  (for ([end (in-range (bytes-length encoded))])
    (check-exn exn:fail?
               (lambda () (decode-app-value (subbytes encoded 0 end)))))
  (check-exn exn:fail?
             (lambda () (decode-app-value (bytes-append encoded #"\0")))))
