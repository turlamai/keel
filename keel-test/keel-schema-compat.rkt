#lang racket/base

(require rackunit
         "../keel/main.rkt")

;; Keep the fixtures small and explicit: each case changes exactly one thing so
;; a rule regression names the rule in the failure.
(define (schema #:id [id "orders"]
                #:revision [revision 1]
                #:records [records '()]
                #:enums [enums '()]
                #:commands [commands '()]
                #:events [events '()]
                #:states [states '()])
  (make-app-schema id revision
                   #:records records
                   #:enums enums
                   #:commands commands
                   #:events events
                   #:states states))

(define (summary old new)
  (for/list ([item (in-list (app-schema-changes old new))])
    (list (schema-change-severity item) (schema-change-path item))))

(define order-v1
  (schema #:records (list (schema-record "Order"
                                         (list (schema-field "id" String))))))

(define (order-with fields)
  (schema #:records (list (schema-record "Order" fields))))

(test-case "an unchanged schema has no changes and is compatible"
  (check-equal? (summary order-v1 order-v1) '())
  (check-true (schema-compatible? order-v1 order-v1))
  (check-equal? (summary order-v1 (schema #:revision 2
                                          #:records (app-schema-records order-v1)))
                '()))

(test-case "adding an optional record field is compatible"
  (define v2 (order-with (list (schema-field "id" String)
                               (schema-field "note" (optional-type String)))))
  (check-equal? (summary order-v1 v2)
                '((compatible "records.Order.fields.note")))
  (check-true (schema-compatible? order-v1 v2)))

(test-case "adding a required record field is breaking"
  (define v2 (order-with (list (schema-field "id" String)
                               (schema-field "total" Int64))))
  (check-equal? (summary order-v1 v2)
                '((breaking "records.Order.fields.total")))
  (check-false (schema-compatible? order-v1 v2)))

(test-case "removing a field and changing a field type are breaking"
  (define removed (schema #:records (list (schema-record "Order" '()))))
  (check-equal? (summary order-v1 removed)
                '((breaking "records.Order.fields.id")))
  (define retyped (order-with (list (schema-field "id" Int64))))
  (check-equal? (summary order-v1 retyped)
                '((breaking "records.Order.fields.id")))
  (check-false (schema-compatible? order-v1 retyped)))

(test-case "record add is compatible and record removal is breaking"
  (define extra (schema #:records (append (app-schema-records order-v1)
                                          (list (schema-record "Customer"
                                                               (list (schema-field "id" String)))))))
  (check-equal? (summary order-v1 extra)
                '((compatible "records.Customer")))
  (check-true (schema-compatible? order-v1 extra))
  (check-equal? (summary extra order-v1)
                '((breaking "records.Customer"))))

(define kind-v1
  (schema #:enums (list (schema-enum "Kind" (list "one-time" "subscription")))))

(test-case "closed enum cases cannot be added or removed"
  (define added (schema #:enums (list (schema-enum "Kind" (list "one-time" "subscription" "trial")))))
  (define removed (schema #:enums (list (schema-enum "Kind" (list "one-time")))))
  (check-equal? (summary kind-v1 added)
                '((breaking "enums.Kind.cases.trial")))
  (check-equal? (summary kind-v1 removed)
                '((breaking "enums.Kind.cases.subscription")))
  (check-false (schema-compatible? kind-v1 added))
  (check-false (schema-compatible? kind-v1 removed)))

(define save-v1
  (schema #:commands (list (schema-command "save"
                                           (list (schema-parameter "value" String))
                                           String
                                           (list "invalid-args")))))

(test-case "command add is compatible; command removal is breaking"
  (check-equal? (summary save-v1 (schema))
                '((breaking "commands.save")))
  (check-equal? (summary (schema) save-v1)
                '((compatible "commands.save")))
  (check-true (schema-compatible? (schema) save-v1)))

(test-case "command parameters are a closed, required surface"
  (define added (schema #:commands (list (schema-command "save"
                                                        (list (schema-parameter "value" String)
                                                              (schema-parameter "comment" String))
                                                        String
                                                        (list "invalid-args")))))
  (define retyped (schema #:commands (list (schema-command "save"
                                                          (list (schema-parameter "value" Int64))
                                                          String
                                                          (list "invalid-args")))))
  (check-equal? (summary save-v1 added)
                '((breaking "commands.save.parameters.comment")))
  (check-equal? (summary save-v1 retyped)
                '((breaking "commands.save.parameters.value")))
  (check-false (schema-compatible? save-v1 added))
  (check-false (schema-compatible? save-v1 retyped)))

(test-case "command result and error-code changes are breaking"
  (define retyped (schema #:commands (list (schema-command "save"
                                                          (list (schema-parameter "value" String))
                                                          Int64
                                                          (list "invalid-args")))))
  (define new-error (schema #:commands (list (schema-command "save"
                                                            (list (schema-parameter "value" String))
                                                            String
                                                            (list "invalid-args" "conflict")))))
  (check-equal? (summary save-v1 retyped)
                '((breaking "commands.save.result")))
  (check-equal? (summary save-v1 new-error)
                '((breaking "commands.save.error-codes.conflict")))
  (check-false (schema-compatible? save-v1 new-error)))

(test-case "event and state changes follow the same closed-value rules"
  (define tick-v1 (schema #:events (list (schema-event "tick" String))))
  (define tick-v2 (schema #:events (list (schema-event "tick" Int64))))
  (check-equal? (summary tick-v1 tick-v2) '((breaking "events.tick")))
  (define ready-v1 (schema #:states (list (schema-state "ready" String))))
  (define ready-v2 (schema #:states (list (schema-state "ready" String)
                                          (schema-state "paused" String))))
  (check-equal? (summary ready-v1 ready-v2) '((compatible "states.paused")))
  (check-true (schema-compatible? ready-v1 ready-v2)))

(test-case "schema identity is part of compatibility; revision alone is not"
  (define renamed (schema #:id "orders2"
                          #:records (app-schema-records order-v1)))
  (check-equal? (summary order-v1 renamed) '((breaking "id")))
  (check-false (schema-compatible? order-v1 renamed)))

(test-case "changes are sorted by path for stable reporting"
  (define many
    (schema #:id "orders2"
            #:records (list (schema-record "Order" (list (schema-field "id" Int64))))
            #:enums (list (schema-enum "Kind" (list "one-time")))))
  (define paths (map cadr (summary order-v1 many)))
  (check-equal? paths (sort paths string<?)))
