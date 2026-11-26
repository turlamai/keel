#lang racket/base
(require rackunit keel/update-contract)

(test-case "version ranges are strict SemVer precedence"
  (check-true (update-version-range? "2.0.0" "1.0.0" #f))
  (check-true (update-version-range? "2.0.0" "1.0.0" "2.0.0-rc.1"))
  (check-false (update-version-range? "2.0.0" "2.0.0+build" #f))
  (check-false (update-version-range? "2.0.0" "1.0.0" "3.0.0"))
  (check-false (update-version-range? "2.0" "1.0.0" #f))
  (check-false (update-version-range? "2.0.0" "1.0.0" 'null)))

(test-case "artifact digest and size validation"
  (check-true (update-artifact-sha256? (make-string 64 #\A)))
  (for ([value (in-list (list #f (make-string 63 #\a)
                              (make-string 64 #\g)
                              (string-append (make-string 64 #\a) "\n")))])
    (check-false (update-artifact-sha256? value)))
  (check-true (update-artifact-size? 1))
  (for ([value (in-list '(0 -1 1.0 #f "1"))])
    (check-false (update-artifact-size? value))))

(test-case "artifact identities are component-aware and nonempty"
  (define app '("windows" "x64" "zip" "app"))
  (define cli '("windows" "x64" "zip" "cli"))
  (define legacy '("windows" "x64" "zip" #f))
  (check-true (unique-update-artifact-identities? (list app cli legacy)))
  (check-false (unique-update-artifact-identities? (list app (map string-copy app))))
  (check-false (unique-update-artifact-identities? '()))
  (for ([value (in-list '(#f ("windows" "x64" "zip")
                          ("windows" "" "zip" #f)
                          ("windows" "x64" "zip" "")
                          (windows "x64" "zip" #f)))])
    (check-false (update-artifact-identity? value))
    (check-false (unique-update-artifact-identities? (list value)))))
