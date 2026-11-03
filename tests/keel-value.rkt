#lang racket/base

(require rackunit
         racket/list
         "../keel/main.rkt")

;; Keep numeric bounds local to the test so they are not accidental API.
(define int64-min (- (expt 2 63)))

(define values
  (list app-null #f #t 0 int64-min 9223372036854775807 0.0 -0.0 1.5
        "" "Racket λ" #"" #"\0\377" '() (list 1 "two" #t)
        (hash) (hash "z" 1 "a" (list #f 2.5))
        (make-app-error "cancelled" "request cancelled"
                        (hash "request-id" 7))))

(for ([value (in-list values)])
  (check-true (app-value? value))
  (define decoded (decode-app-value (encode-app-value value)))
  (check-equal? (encode-app-value decoded) (encode-app-value value)))

(check-equal? (encode-app-value (hash "b" 2 "a" 1))
              (encode-app-value (hash "a" 1 "b" 2)))

;; An eq-based hash can hold two distinct string objects with equal contents.
;; That is not a canonical map: encoding it would emit duplicate keys that the
;; decoder rejects, so the value must be rejected before encoding.
(define duplicate-key-hash
  (make-immutable-hasheq
   (list (cons (string-copy "a") 1)
         (cons (string-copy "a") 2))))
(check-equal? (hash-count duplicate-key-hash) 2)
(check-false (app-value? duplicate-key-hash))
(check-exn exn:fail? (lambda () (encode-app-value duplicate-key-hash)))

;; A canonical eq-based hash with distinct keys remains a valid value.
(define canonical-hasheq (make-immutable-hasheq (list (cons "a" 1))))
(check-true (app-value? canonical-hasheq))
(check-equal? (encode-app-value (decode-app-value (encode-app-value canonical-hasheq)))
              (encode-app-value canonical-hasheq))

(for ([invalid (in-list (list +nan.0 +inf.0 -inf.0
                              (expt 2 63)
                              (sub1 (- (expt 2 63)))
                              (make-hash '(("a" . 1)))
                              (hash 'a 1)
                              #\x))])
  (check-false (app-value? invalid))
  (check-exn exn:fail? (lambda () (encode-app-value invalid))))

(check-exn exn:fail? (lambda () (decode-app-value (bytes #xff))))
(check-exn exn:fail?
           (lambda () (decode-app-value (bytes #x04 #x01 0 0 0 #xff))))
(check-exn exn:fail?
           (lambda ()
             ;; Map keys b, then a: valid values, non-canonical order.
             (decode-app-value
              (bytes #x08 #x02 0 0 0
                     #x04 #x01 0 0 0 #x62 #x00
                     #x04 #x01 0 0 0 #x61 #x00))))

(define too-deep
  (for/fold ([value app-null]) ([index (in-range (add1 max-value-depth))])
    (list value)))
(check-exn exn:fail? (lambda () (encode-app-value too-deep)))
