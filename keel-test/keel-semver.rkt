#lang racket/base
(require rackunit keel/semver)

(define precedence
  '("1.0.0-alpha" "1.0.0-alpha.1" "1.0.0-alpha.beta"
    "1.0.0-beta" "1.0.0-beta.2" "1.0.0-beta.11"
    "1.0.0-rc.1" "1.0.0" "1.0.1" "1.1.0" "2.0.0"))
(for* ([(left i) (in-indexed (in-list precedence))]
       [(right j) (in-indexed (in-list precedence))])
  (check-true (semver? left))
  (check-equal? (semver-compare left right) (cond [(< i j) -1] [(> i j) 1] [else 0]))
  (check-equal? (semver<? left right) (< i j))
  (check-equal? (semver<=? left right) (<= i j))
  (check-equal? (semver=? left right) (= i j))
  (check-equal? (semver>=? left right) (>= i j))
  (check-equal? (semver>? left right) (> i j)))
(for ([invalid (in-list '(#f 1 "" "v1.0.0" "1.0" "01.0.0" "1.00.0"
                          "1.0.00" "1.0.0-01" "1.0.0-a..b" "1.0.0+"
                          "1.0.0-α" "1.0.0 " "1.0.0\n"))])
  (check-false (semver? invalid))
  (check-exn exn:fail:contract? (lambda () (semver-compare invalid "1.0.0")))
  (check-exn exn:fail:contract? (lambda () (semver-compare "1.0.0" invalid))))
(check-true (semver=? "1.0.0+001" "1.0.0+build.99"))
(check-true (semver=? "1.0.0-rc.1+foo" "1.0.0-rc.1+bar"))
;; Racket's string->number accepts exponent and complex notation; SemVer does not.
(check-true (semver<? "1.0.0-999" "1.0.0-1e2"))
(check-true (semver<? "1.0.0-999" "1.0.0-1i"))
(check-true (semver<? "1.0.0-999" "1.0.0-1-2i"))
(check-true (semver<? "1.0.0-2" "1.0.0-10"))
(check-true (semver<? "1.0.0-A" "1.0.0-a"))
(check-true (semver<? "999999999999999999999.0.0" "1000000000000000000000.0.0"))
