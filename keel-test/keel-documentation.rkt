#lang racket/base

;; Markdown dead-link check over the repository. Named keel-documentation
;; Modules live in the private `keel-test/` collection. The `keel-` prefix
;; remains mandatory as defense in depth against the shared top-level
;; `tests` collection hazard; keel-collection-names.rkt enforces the rule.

(require rackunit
         racket/file
         racket/list
         racket/path
         racket/runtime-path
         racket/string)

(define-runtime-path repository-root/raw "..")
(define repository-root (simplify-path repository-root/raw #t))

;; The official package builder installs a source archive, not a Git checkout.
;; GitHub workflow files are maintainer tooling and are not part of that archive.
;; In a repository checkout (including GitHub Actions) they must exist; in a
;; catalog installation, only this one checkout-only Markdown link is exempt.
(define source-checkout?
  (directory-exists? (build-path repository-root ".git")))
(define catalog-release-workflow
  (simplify-path
   (build-path repository-root ".github" "workflows" "catalog-release-gate.yml")
   #f))

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
       (or (file-exists? resolved)
           (directory-exists? resolved)
           (and (not source-checkout?)
                (equal? resolved catalog-release-workflow)))
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
(when source-checkout?
  (check-true
   (file-exists? catalog-release-workflow)
   "repository checkout must include the manually triggered catalog install gate"))
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
