#lang racket/base

(require rackunit
         racket/list
         "../keel/main.rkt")

(define generator (make-pseudo-random-generator))

(define (random-string maximum)
  (list->string
   (for/list ([index (in-range (random (add1 maximum)))])
     (integer->char (+ 32 (random 95))))))

(define (random-leaf)
  (case (random 7)
    [(0) app-null]
    [(1) (zero? (random 2))]
    [(2) (- (random 2000001) 1000000)]
    [(3) (/ (exact->inexact (- (random 2000001) 1000000)) 10.0)]
    [(4) (random-string 24)]
    [(5) (apply bytes (for/list ([index (in-range (random 24))]) (random 256)))]
    [else (make-app-error "invalid-args" (random-string 16))]))

(define (random-value depth)
  (if (>= depth 4)
      (random-leaf)
      (case (random 10)
        [(0 1 2 3 4 5) (random-leaf)]
        [(6 7)
         (for/list ([index (in-range (random 6))])
           (random-value (add1 depth)))]
        [(8)
         (for/fold ([result (hash)])
                   ([index (in-range (random 6))])
           (hash-set result (format "k~a-~a" index (random 1000))
                     (random-value (add1 depth))))]
        [else
         (make-app-error "internal" (random-string 16)
                         (random-value (add1 depth)))])))

(parameterize ([current-pseudo-random-generator generator])
  (random-seed 1962026)
  (for ([iteration (in-range 2000)])
    (define value (random-value 0))
    (define encoded (encode-app-value value))
    (check-equal? (encode-app-value (decode-app-value encoded)) encoded))

  ;; Arbitrary bytes must either be rejected or converge to a canonical value.
  (for ([iteration (in-range 2000)])
    (define input
      (apply bytes (for/list ([index (in-range (random 65))]) (random 256))))
    (with-handlers ([exn:fail? void])
      (define decoded (decode-app-value input))
      (check-equal? (decode-app-value (encode-app-value decoded)) decoded))))
