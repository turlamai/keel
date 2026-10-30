#lang racket/base

;; Markdown dead-link check over the repository. Named keel-documentation
;; because `tests/` is a collection shared by every family package: rivet
;; already ships `tests/documentation`, and two packages claiming the same
;; module path cannot coexist in one installation (raco pkg install conflict).
;; The keel- prefix is mandatory for every module in this directory;
;; tests/keel-collection-names.rkt enforces the rule.

(require rackunit
         racket/file
         racket/list
         racket/path
         racket/runtime-path
         racket/string)

(define-runtime-path repository-root/raw "..")
(define repository-root (simplify-path repository-root/raw #t))

(define (markdown-file? path)
  (and (file-exists? path)
       (equal? (path-get-extension path) #".md")))

(define markdown-files
  (append
   (filter markdown-file?
           (directory-list repository-root #:build? #t))
   (find-files markdown-file? (build-path repository-root "docs"))))

(define markdown-link-pattern #px"\\[[^]]*\\]\\(([^)]+)\\)")
(define external-link-pattern #px"^(?:https?://|mailto:|#)")

(define (strip-fragment target)
  (car (string-split target "#" #:trim? #f)))

(for* ([document (in-list markdown-files)]
       [match (in-list
               (regexp-match* markdown-link-pattern
                              (file->string document)
                              #:match-select values))])
  (define target (cadr match))
  (unless (regexp-match? external-link-pattern target)
    (define local-target (strip-fragment target))
    (unless (string=? local-target "")
      (define resolved
        (simplify-path (build-path (path-only document) local-target) #f))
      (check-true
       (or (file-exists? resolved) (directory-exists? resolved))
       (format "~a links to missing local target ~a"
               (find-relative-path repository-root document)
               target)))))

;; Downstream workflow dispatch must use the current GitHub owner.
(define contributor-guide
  (file->string (build-path repository-root "CONTRIBUTING.md")))
(for ([owner '("turlamai/rivet" "turlamai/glaze")])
  (check-true (string-contains? contributor-guide owner)
              (format "downstream release handoff must reference ~a" owner)))
(check-false
 (string-contains? contributor-guide "turinglambdaai/")
 "contributing guide must not retain retired GitHub organization paths")
(define agent-guide
  (file->string (build-path repository-root "AGENTS.md")))
(check-false
 (string-contains? agent-guide "turinglambdaai/")
 "maintainer agent instructions must not dispatch retired GitHub owners")
(for ([entry '("README.md" "README.zh-CN.md" "CONTRIBUTING.md" "AGENTS.md")])
  (check-true
   (string-contains?
    (file->string (build-path repository-root entry))
    "docs/package-catalog-release.md")
   (format "~a must link the published catalog release gate" entry)))
(check-true
 (file-exists?
  (build-path repository-root ".github/workflows/catalog-release-gate.yml"))
 "release verification must ship a manually triggered catalog install gate")
(for ([guide (in-list (list agent-guide contributor-guide))])
  (check-true
   (string-contains? guide "docs/package-catalog-release.md")
   "release/agent guidance must link the official catalog gate"))

(define family-document-relative "docs/family-architecture.md")
(define family-document
  (file->string (build-path repository-root family-document-relative)))

(for ([repository '("Keel" "Rivet" "Glaze" "Permit" "Commerce")])
  (check-true
   (string-contains? family-document repository)
   (format "~a must name ~a" family-document-relative repository)))

(for ([entry '("AGENTS.md" "CONTRIBUTING.md" "README.md")])
  (check-true
   (string-contains? (file->string (build-path repository-root entry))
                     family-document-relative)
   (format "~a must link the canonical family architecture" entry)))
