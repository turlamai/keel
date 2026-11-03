#lang racket/base

(require racket/list
         racket/math
         "error.rkt"
         (submod "error.rkt" private))

(provide app-null
         app-null?
         make-app-error
         app-value?
         encode-app-value
         decode-app-value
         max-encoded-value-size
         max-value-depth
         max-value-nodes)

;; Version 1 is deliberately a value codec, not a transport frame. RVT1 and
;; GLZ1 retain their own request, response, event, and streaming envelopes.
(define max-encoded-value-size (* 64 1024 1024))
(define max-value-depth 64)
(define max-value-nodes (expt 2 18))

(define app-null (void))
(define app-null? void?)

;; Existing Rivet tags stay byte-identical. New tags are appended so an RVT1
;; implementation can adopt the extended union in a future protocol version
;; without reinterpretation of its established subset.
(define tag:null #x00)
(define tag:false #x01)
(define tag:true #x02)
(define tag:int64 #x03)
(define tag:string #x04)
(define tag:bytes #x05)
(define tag:list #x06)
(define tag:float64 #x07)
(define tag:map #x08)
(define tag:error #x09)

(define int64-min (- (expt 2 63)))
(define int64-max (sub1 (expt 2 63)))

(define (make-app-error code message [data app-null])
  (unless (app-error-code? code)
    (raise-argument-error 'make-app-error "app-error-code?" code))
  (unless (string? message)
    (raise-argument-error 'make-app-error "string?" message))
  (unless (app-value? data)
    (raise-argument-error 'make-app-error "app-value?" data))
  (make-unchecked-app-error code message data))

(define (finite-inexact-real? value)
  (and (real? value)
       (inexact? value)
       (not (nan? value))
       (not (infinite? value))))

;; `hash?` also accepts eq-based hashes. Two distinct string objects with the
;; same contents are separate keys in a hasheq, so accepting that hash would let
;; `encode-app-value` emit duplicate map keys that its own decoder rejects.
;; Rebuilding an equal?-based hash merges such keys; a count mismatch means the
;; map is not canonical. Equal?-based hashes skip the rebuild.
(define (canonical-map? value)
  (and (hash? value)
       (immutable? value)
       (for/and ([key (in-hash-keys value)]) (string? key))
       (or (hash-equal? value)
           (= (hash-count value)
              (hash-count (make-immutable-hash (hash->list value)))))))

(define (utf8-key<? left right)
  (bytes<? (string->bytes/utf-8 left)
           (string->bytes/utf-8 right)))

;; Returns a non-negative length, 'cycle, or 'limit. Stopping at the current
;; node budget avoids traversing an attacker-controlled list twice without a
;; bound before encoding begins.
(define (bounded-list-length value limit)
  (let loop ([rest value] [slow value] [count 0] [advance-slow? #f])
    (cond
      [(null? rest) count]
      [(not (pair? rest)) 'improper]
      [(>= count limit) 'limit]
      [else
       (define next (cdr rest))
       (define next-slow
         (if advance-slow?
             (if (pair? slow) (cdr slow) slow)
             slow))
       (if (and (pair? next) (eq? next next-slow))
           'cycle
           (loop next next-slow (add1 count) (not advance-slow?)))])))

(define (encode-app-value value)
  (define out (open-output-bytes))
  (define remaining-nodes max-value-nodes)
  (define remaining-bytes max-encoded-value-size)

  (define (consume-node!)
    (when (zero? remaining-nodes)
      (raise-arguments-error 'encode-app-value
                             "value node count exceeds the keel limit"
                             "maximum nodes" max-value-nodes))
    (set! remaining-nodes (sub1 remaining-nodes)))

  (define (consume-bytes! count)
    (when (> count remaining-bytes)
      (raise-arguments-error 'encode-app-value
                             "encoded value exceeds the keel size limit"
                             "maximum bytes" max-encoded-value-size))
    (set! remaining-bytes (- remaining-bytes count)))

  (define (emit-byte! value)
    (consume-bytes! 1)
    (write-byte value out))

  (define (emit-bytes! value)
    (consume-bytes! (bytes-length value))
    (write-bytes value out))

  (define (emit-u32! value)
    (emit-bytes! (integer->integer-bytes value 4 #f #f)))

  (define (emit-string-body! value)
    (define encoded (string->bytes/utf-8 value))
    (when (> (bytes-length encoded) #xffffffff)
      (raise-arguments-error 'encode-app-value
                             "string exceeds the keel length field"
                             "length" (bytes-length encoded)))
    (emit-u32! (bytes-length encoded))
    (emit-bytes! encoded))

  (define (emit value depth)
    (consume-node!)
    (cond
      [(app-null? value)
       (emit-byte! tag:null)]
      [(eq? value #f)
       (emit-byte! tag:false)]
      [(eq? value #t)
       (emit-byte! tag:true)]
      [(and (exact-integer? value) (<= int64-min value int64-max))
       (emit-byte! tag:int64)
       (emit-bytes! (integer->integer-bytes value 8 #t #f))]
      [(finite-inexact-real? value)
       (emit-byte! tag:float64)
       (emit-bytes!
        (real->floating-point-bytes (real->double-flonum value) 8 #f))]
      [(string? value)
       (emit-byte! tag:string)
       (emit-string-body! value)]
      [(bytes? value)
       (when (> (bytes-length value) #xffffffff)
         (raise-arguments-error 'encode-app-value
                                "byte string exceeds the keel length field"
                                "length" (bytes-length value)))
       (emit-byte! tag:bytes)
       (emit-u32! (bytes-length value))
       (emit-bytes! value)]
      [(or (null? value) (pair? value))
       (when (>= depth max-value-depth)
         (raise-arguments-error 'encode-app-value
                                "value nesting exceeds the keel limit"
                                "maximum depth" max-value-depth))
       (define count (bounded-list-length value remaining-nodes))
       (unless (exact-nonnegative-integer? count)
         (error 'encode-app-value
                (case count
                  [(cycle) "value contains a cyclic list"]
                  [(limit) "value node count exceeds the keel limit"]
                  [else "value contains an improper list"])))
       (emit-byte! tag:list)
       (emit-u32! count)
       (for ([item (in-list value)]) (emit item (add1 depth)))]
      [(canonical-map? value)
       (when (>= depth max-value-depth)
         (raise-arguments-error 'encode-app-value
                                "value nesting exceeds the keel limit"
                                "maximum depth" max-value-depth))
       (define keys (sort (hash-keys value) utf8-key<?))
       (when (> (* 2 (length keys)) remaining-nodes)
         (raise-arguments-error 'encode-app-value
                                "value node count exceeds the keel limit"
                                "maximum nodes" max-value-nodes))
       (emit-byte! tag:map)
       (emit-u32! (length keys))
       (for ([key (in-list keys)])
         (emit key (add1 depth))
         (emit (hash-ref value key) (add1 depth)))]
      [(app-error? value)
       (when (>= depth max-value-depth)
         (raise-arguments-error 'encode-app-value
                                "value nesting exceeds the keel limit"
                                "maximum depth" max-value-depth))
       (unless (app-error-code? (app-error-code value))
         (raise-argument-error 'encode-app-value
                               "app-error with an app-error-code? code"
                               value))
       (unless (string? (app-error-message value))
         (raise-argument-error 'encode-app-value
                               "app-error with a string? message"
                               value))
       (emit-byte! tag:error)
       (emit (app-error-code value) (add1 depth))
       (emit (app-error-message value) (add1 depth))
       (emit (app-error-data value) (add1 depth))]
      [else
       (error 'encode-app-value "value is not in the keel v1 union")]))

  (emit value 0)
  (get-output-bytes out))

(define (decode-app-value encoded)
  (unless (bytes? encoded)
    (raise-argument-error 'decode-app-value "bytes?" encoded))
  (when (> (bytes-length encoded) max-encoded-value-size)
    (raise-arguments-error 'decode-app-value
                           "encoded value exceeds the keel size limit"
                           "length" (bytes-length encoded)
                           "maximum" max-encoded-value-size))
  (define in (open-input-bytes encoded))
  (define remaining-nodes max-value-nodes)

  (define (consume-node!)
    (when (zero? remaining-nodes)
      (error 'decode-app-value
             "value node count exceeds the keel limit (~a)"
             max-value-nodes))
    (set! remaining-nodes (sub1 remaining-nodes)))

  (define (read-exactly count kind)
    (define value (read-bytes count in))
    (when (or (eof-object? value) (< (bytes-length value) count))
      (error 'decode-app-value "unexpected EOF in ~a" kind))
    value)

  (define (read-u32 kind)
    (integer-bytes->integer (read-exactly 4 kind) #f #f))

  (define (read-sized-bytes kind)
    (define count (read-u32 kind))
    (when (> count (- (bytes-length encoded) (file-position in)))
      (error 'decode-app-value "impossible ~a length: ~a" kind count))
    (read-exactly count kind))

  (define (read-one depth)
    (consume-node!)
    (define tag (read-byte in))
    (when (eof-object? tag) (error 'decode-app-value "unexpected EOF"))
    (case tag
      [(#x00) app-null]
      [(#x01) #f]
      [(#x02) #t]
      [(#x03)
       (integer-bytes->integer (read-exactly 8 "int64") #t #f)]
      [(#x04)
       (define raw (read-sized-bytes "string"))
       (with-handlers ([exn:fail?
                        (lambda (_)
                          (error 'decode-app-value "invalid UTF-8 string"))])
         (bytes->string/utf-8 raw #f))]
      [(#x05) (read-sized-bytes "bytes")]
      [(#x06)
       (when (>= depth max-value-depth)
         (error 'decode-app-value
                "value nesting exceeds the keel limit (~a)"
                max-value-depth))
       (define count (read-u32 "list"))
       (when (> count remaining-nodes)
         (error 'decode-app-value
                "value node count exceeds the keel limit (~a)"
                max-value-nodes))
       (when (> count (- (bytes-length encoded) (file-position in)))
         (error 'decode-app-value "impossible list length: ~a" count))
       (for/list ([index (in-range count)]) (read-one (add1 depth)))]
      [(#x07)
       (define value
         (floating-point-bytes->real (read-exactly 8 "float64") #f))
       (unless (finite-inexact-real? value)
         (error 'decode-app-value "non-finite Float64 is not canonical"))
       value]
      [(#x08)
       (when (>= depth max-value-depth)
         (error 'decode-app-value
                "value nesting exceeds the keel limit (~a)"
                max-value-depth))
       (define count (read-u32 "map"))
       (when (> count (quotient remaining-nodes 2))
         (error 'decode-app-value
                "value node count exceeds the keel limit (~a)"
                max-value-nodes))
       (define-values (result _)
         (for/fold ([result (hash)] [previous-key-bytes #f])
                   ([index (in-range count)])
           (define key (read-one (add1 depth)))
           (unless (string? key)
             (error 'decode-app-value "map key is not a String"))
           (define key-bytes (string->bytes/utf-8 key))
           (when (and previous-key-bytes
                      (not (bytes<? previous-key-bytes key-bytes)))
             (error 'decode-app-value
                    "map keys are duplicated or not in canonical order"))
           (values (hash-set result key (read-one (add1 depth))) key-bytes)))
       result]
      [(#x09)
       (when (>= depth max-value-depth)
         (error 'decode-app-value
                "value nesting exceeds the keel limit (~a)"
                max-value-depth))
       (define code (read-one (add1 depth)))
       (define message (read-one (add1 depth)))
       (define data (read-one (add1 depth)))
       (unless (app-error-code? code)
         (error 'decode-app-value "structured error code is invalid"))
       (unless (string? message)
         (error 'decode-app-value "structured error message is not a String"))
       (make-app-error code message data)]
      [else (error 'decode-app-value "unknown value tag: ~a" tag)]))

  (define value (read-one 0))
  (unless (eof-object? (read-byte in))
    (error 'decode-app-value "trailing bytes after value"))
  value)

(define (app-value? value)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (encode-app-value value)
    #t))
