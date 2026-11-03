#lang racket/base

;; Schema compatibility for the transport-neutral contract. RVT1 and GLZ1 own
;; their own wire envelopes, but both compare the same Keel schema: a change is
;; breaking when an existing peer can observe a different value, name, type, or
;; closed case set, and compatible otherwise.
;;
;; The rules are deliberately conservative. "Adding an enum case" and "adding a
;; command error code" are breaking because both are closed vocabularies that a
;; consumer must handle exhaustively; "adding an optional record field" is
;; compatible because earlier values remain valid under the new descriptor.

(require racket/list
         racket/string
         "schema.rkt")

(provide (struct-out schema-change)
         app-schema-changes
         schema-compatible?)

;; severity is 'breaking or 'compatible. path is a stable dotted location
;; (for example "records.Order.fields.total"), detail is human-readable.
(struct schema-change (severity path detail)
  #:transparent)

(define (change severity path detail)
  (schema-change severity path detail))

(define (index-by key items)
  (for/hash ([item (in-list items)]) (values (key item) item)))

(define (names-without index other)
  (for/list ([name (in-list (sort (hash-keys index) string<?))]
             #:unless (hash-has-key? other name))
    name))

(define (common-names left right)
  (for/list ([name (in-list (sort (hash-keys left) string<?))]
             #:when (hash-has-key? right name))
    name))

(define (type-changes path old-type new-type)
  (cond
    [(equal? old-type new-type) '()]
    [else
     (list
      (change 'breaking
              path
              (format "type changed from ~a to ~a"
                      (schema-type->app-value old-type)
                      (schema-type->app-value new-type))))]))

;; ---- records ----

(define (field-changes record-name old-record new-record)
  (define old-fields (index-by schema-field-name (schema-record-fields old-record)))
  (define new-fields (index-by schema-field-name (schema-record-fields new-record)))
  (append
   (for/list ([name (in-list (names-without old-fields new-fields))])
     (change 'breaking
             (format "records.~a.fields.~a" record-name name)
             "field removed"))
   (for/list ([name (in-list (names-without new-fields old-fields))])
     (define field (hash-ref new-fields name))
     (if (optional-type? (schema-field-type field))
         (change 'compatible
                 (format "records.~a.fields.~a" record-name name)
                 "optional field added")
         (change 'breaking
                 (format "records.~a.fields.~a" record-name name)
                 "required field added")))
   (append*
    (for/list ([name (in-list (common-names old-fields new-fields))])
      (type-changes (format "records.~a.fields.~a" record-name name)
                    (schema-field-type (hash-ref old-fields name))
                    (schema-field-type (hash-ref new-fields name)))))))

(define (record-changes old-schema new-schema)
  (define old-records (index-by schema-record-name (app-schema-records old-schema)))
  (define new-records (index-by schema-record-name (app-schema-records new-schema)))
  (append
   (for/list ([name (in-list (names-without old-records new-records))])
     (change 'breaking (format "records.~a" name) "record removed"))
   (for/list ([name (in-list (names-without new-records old-records))])
     (change 'compatible (format "records.~a" name) "record added"))
   (append*
    (for/list ([name (in-list (common-names old-records new-records))])
      (field-changes name
                     (hash-ref old-records name)
                     (hash-ref new-records name))))))

;; ---- enums ----

(define (enum-changes old-schema new-schema)
  (define old-enums (index-by schema-enum-name (app-schema-enums old-schema)))
  (define new-enums (index-by schema-enum-name (app-schema-enums new-schema)))
  (append
   (for/list ([name (in-list (names-without old-enums new-enums))])
     (change 'breaking (format "enums.~a" name) "enum removed"))
   (for/list ([name (in-list (names-without new-enums old-enums))])
     (change 'compatible (format "enums.~a" name) "enum added"))
   (append*
    (for/list ([name (in-list (common-names old-enums new-enums))])
      (define old-cases (schema-enum-cases (hash-ref old-enums name)))
      (define new-cases (schema-enum-cases (hash-ref new-enums name)))
      (append
       (for/list ([case (in-list new-cases)]
                  #:unless (member case old-cases))
         (change 'breaking (format "enums.~a.cases.~a" name case)
                 "closed enum case added"))
       (for/list ([case (in-list old-cases)]
                  #:unless (member case new-cases))
         (change 'breaking (format "enums.~a.cases.~a" name case)
                 "enum case removed")))))))

;; ---- commands ----

(define (parameter-changes command-name old-command new-command)
  (define old-params (index-by schema-parameter-name (schema-command-parameters old-command)))
  (define new-params (index-by schema-parameter-name (schema-command-parameters new-command)))
  (append
   (for/list ([name (in-list (names-without old-params new-params))])
     (change 'breaking
             (format "commands.~a.parameters.~a" command-name name)
             "parameter removed"))
   (for/list ([name (in-list (names-without new-params old-params))])
     (change 'breaking
             (format "commands.~a.parameters.~a" command-name name)
             "required parameter added"))
   (append*
    (for/list ([name (in-list (common-names old-params new-params))])
      (type-changes (format "commands.~a.parameters.~a" command-name name)
                    (schema-parameter-type (hash-ref old-params name))
                    (schema-parameter-type (hash-ref new-params name)))))))

(define (command-changes old-schema new-schema)
  (define old-commands (index-by schema-command-name (app-schema-commands old-schema)))
  (define new-commands (index-by schema-command-name (app-schema-commands new-schema)))
  (append
   (for/list ([name (in-list (names-without old-commands new-commands))])
     (change 'breaking (format "commands.~a" name) "command removed"))
   (for/list ([name (in-list (names-without new-commands old-commands))])
     (change 'compatible (format "commands.~a" name) "command added"))
   (append*
    (for/list ([name (in-list (common-names old-commands new-commands))])
      (define old-command (hash-ref old-commands name))
      (define new-command (hash-ref new-commands name))
      (define old-errors (schema-command-error-codes old-command))
      (define new-errors (schema-command-error-codes new-command))
      (append
       (parameter-changes name old-command new-command)
       (type-changes (format "commands.~a.result" name)
                     (schema-command-result old-command)
                     (schema-command-result new-command))
       (for/list ([code (in-list (sort (append old-errors new-errors) string<?))]
                  #:unless (and (member code old-errors) (member code new-errors)))
         (change 'breaking
                 (format "commands.~a.error-codes.~a" name code)
                 (if (member code old-errors)
                     "declared error code removed"
                     "declared error code added"))))))))

;; ---- events and states ----

(define (event-changes old-schema new-schema)
  (define old-events (index-by schema-event-name (app-schema-events old-schema)))
  (define new-events (index-by schema-event-name (app-schema-events new-schema)))
  (append
   (for/list ([name (in-list (names-without old-events new-events))])
     (change 'breaking (format "events.~a" name) "event removed"))
   (for/list ([name (in-list (names-without new-events old-events))])
     (change 'compatible (format "events.~a" name) "event added"))
   (append*
    (for/list ([name (in-list (common-names old-events new-events))])
      (type-changes (format "events.~a" name)
                    (schema-event-type (hash-ref old-events name))
                    (schema-event-type (hash-ref new-events name)))))))

(define (state-changes old-schema new-schema)
  (define old-states (index-by schema-state-name (app-schema-states old-schema)))
  (define new-states (index-by schema-state-name (app-schema-states new-schema)))
  (append
   (for/list ([name (in-list (names-without old-states new-states))])
     (change 'breaking (format "states.~a" name) "state removed"))
   (for/list ([name (in-list (names-without new-states old-states))])
     (change 'compatible (format "states.~a" name) "state added"))
   (append*
    (for/list ([name (in-list (common-names old-states new-states))])
      (type-changes (format "states.~a" name)
                    (schema-state-type (hash-ref old-states name))
                    (schema-state-type (hash-ref new-states name)))))))

;; ---- public API ----

(define (app-schema-changes old-schema new-schema)
  (unless (app-schema? old-schema)
    (raise-argument-error 'app-schema-changes "app-schema?" old-schema))
  (unless (app-schema? new-schema)
    (raise-argument-error 'app-schema-changes "app-schema?" new-schema))
  (define revisions
    (if (equal? (app-schema-id old-schema) (app-schema-id new-schema))
        '()
        (list (change 'breaking
                      "id"
                      (format "schema id changed from ~s to ~s"
                              (app-schema-id old-schema)
                              (app-schema-id new-schema))))))
  (sort (append revisions
                (record-changes old-schema new-schema)
                (enum-changes old-schema new-schema)
                (command-changes old-schema new-schema)
                (event-changes old-schema new-schema)
                (state-changes old-schema new-schema))
        string<?
        #:key schema-change-path))

(define (schema-compatible? old-schema new-schema)
  (for/and ([item (in-list (app-schema-changes old-schema new-schema))])
    (eq? (schema-change-severity item) 'compatible)))
