#lang racket/base
(require rackunit keel/update-manifest)

(define (artifact #:component [component #f] #:size [size 1]
                  #:sha [sha (make-string 64 #\A)] #:url [url "https://example.test/a"]
                  #:arguments [arguments '("--quiet")] #:signature [signature #f])
  (update-artifact "windows" "x64" url sha size "zip" arguments component signature))
(define (manifest artifacts #:version [version "2.0.0"] #:minimum [minimum "1.0.0"]
                  #:previous [previous #f] #:build [build 2] #:rollout [rollout 100])
  (update-manifest "example" version build "stable" "2026-11-26T00:00:00Z"
                   minimum previous #f rollout artifacts))

(test-case "normalized records retain both component and signature"
  (define app (artifact #:component "app" #:signature "opaque-signature"))
  (define cli (artifact #:component "cli"))
  (define m (manifest (list app cli)))
  (check-equal? (update-manifest-artifacts m) (list app cli))
  (check-equal? (update-artifact-sha256 app) (make-string 64 #\a))
  (check-equal? (update-artifact-identity app) '("windows" "x64" "zip" "app"))
  (check-equal? (update-artifact-signature app) "opaque-signature")
  (check-false (update-artifact-signature cli)))

(test-case "invalid records fail at construction"
  (for ([thunk (in-list
                (list (lambda () (artifact #:size 0))
                      (lambda () (artifact #:sha "bad"))
                      (lambda () (artifact #:url ""))
                      (lambda () (artifact #:arguments '(1)))
                      (lambda () (artifact #:component ""))
                      (lambda () (artifact #:signature ""))
                      (lambda () (manifest '()))
                      (lambda () (manifest (list (artifact) (artifact))))
                      (lambda () (manifest '(not-artifact)))
                      (lambda () (manifest (list (artifact)) #:minimum "2.0.0"))
                      (lambda () (manifest (list (artifact)) #:previous "3.0.0"))
                      (lambda () (manifest (list (artifact)) #:version "2"))
                      (lambda () (manifest (list (artifact)) #:build 0))
                      (lambda () (manifest (list (artifact)) #:rollout 101))))])
    (check-exn exn:fail:contract? thunk)))

(test-case "caller mutation cannot change normalized fields after validation"
  (define url (string-copy "https://example.test/a"))
  (define arg (string-copy "--quiet"))
  (define a (artifact #:url url #:arguments (list arg)))
  (define version (string-copy "2.0.0"))
  (define m (manifest (list a) #:version version))
  (string-set! url 0 #\X)
  (string-set! arg 0 #\X)
  (string-set! version 0 #\9)
  (check-equal? (update-artifact-url a) "https://example.test/a")
  (check-equal? (update-artifact-arguments a) '("--quiet"))
  (check-equal? (update-manifest-version m) "2.0.0")
  (check-true (immutable? (update-artifact-url a)))
  (check-true (immutable? (car (update-artifact-arguments a))))
  (check-true (immutable? (update-manifest-version m))))
