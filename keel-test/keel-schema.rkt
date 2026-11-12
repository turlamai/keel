#lang racket/base

(require rackunit
         "../keel/main.rkt")

(define task-type (reference-type 'Task))
(define status-type (reference-type "TaskStatus"))

(define TaskStatus
  (schema-enum 'TaskStatus '(backlog active done)))

(define Task
  (schema-record
   'Task
   (list (schema-field 'id Int64)
         (schema-field 'title String)
         (schema-field 'status status-type)
         (schema-field 'notes (optional-type String))
         (schema-field 'metadata (map-type Value)))))

(define create-task
  (schema-command
   'create-task
   (list (schema-parameter 'title String)
         (schema-parameter 'status status-type))
   task-type
   '("invalid-args" "conflict")))

(define schema
  (make-app-schema
   "org.racket.taskboard"
   3
   #:records (list Task)
   #:enums (list TaskStatus)
   #:commands
   (list (schema-command 'list-tasks '() (list-type task-type) '())
         create-task
         (schema-command 'quit '() Unit '()))
   #:events (list (schema-event 'task-saved task-type))
   #:states (list (schema-state 'tasks (list-type task-type)))))

(check-true (app-schema? schema))
(check-equal? (app-schema-id schema) "org.racket.taskboard")
(check-equal? (map schema-command-name (app-schema-commands schema))
              '("create-task" "list-tasks" "quit"))
(check-equal? (schema-record-name Task) "Task")
(check-equal? (schema-enum-cases TaskStatus) '("backlog" "active" "done"))

(define as-value (app-schema->app-value schema))
(check-true (app-value? as-value))
(check-equal? (hash-ref as-value "contract") 1)
(check-equal? (hash-ref as-value "revision") 3)
(check-equal? (decode-app-value (encode-app-schema schema)) as-value)

;; Declaration order between named definitions and endpoints is not semantic;
;; canonical encoding sorts those collections by name. Record fields, command
;; parameters, and enum cases retain declaration order because it is semantic.
(define reordered
  (make-app-schema
   "org.racket.taskboard"
   3
   #:records (list Task)
   #:enums (list TaskStatus)
   #:commands (reverse (app-schema-commands schema))
   #:events (app-schema-events schema)
   #:states (app-schema-states schema)))
(check-equal? (encode-app-schema reordered) (encode-app-schema schema))

(for ([type (in-list (list Null Bool Int64 Float64 String Bytes Value Error Unit
                           (list-type String)
                           (map-type Value)
                           (optional-type Int64)
                           (reference-type 'Task)))])
  (check-true (schema-type? type))
  (check-true (app-value? (schema-type->app-value type))))

(for ([good-name (in-list '("signed-in?" "save!" "string->bytes" "任务状态" "two words"))])
  (check-true (schema-name? good-name)))

(for ([bad-name (in-list (list ""
                               "line\nbreak"
                               (string-append "hidden" (string #\u200b) "format")
                               (make-string 256 #\a)))])
  (check-false (schema-name? bad-name)))

(check-exn exn:fail:contract? (lambda () (scalar-type 'Unknown)))
(check-exn exn:fail:contract? (lambda () (optional-type Unit)))
(check-exn exn:fail:contract?
           (lambda ()
             (schema-record 'Duplicate
                            (list (schema-field 'value Int64)
                                  (schema-field 'value String)))))
(check-exn exn:fail:contract? (lambda () (schema-enum 'Empty '())))
(check-exn exn:fail:contract?
           (lambda ()
             (schema-command 'bad
                             (list (schema-parameter 'value String)
                                   (schema-parameter 'value Int64))
                             Unit
                             '())))
(check-exn exn:fail:contract?
           (lambda ()
             (schema-command 'bad '() Unit '("invalid-args" "invalid-args"))))
(check-exn exn:fail:contract?
           (lambda ()
             (make-app-schema "org.racket.bad" 1
                              #:records (list (schema-record 'Thing '()))
                              #:enums (list (schema-enum 'Thing '(one))))))
(check-exn exn:fail:contract?
           (lambda ()
             (make-app-schema "org.racket.bad" 1
                              #:commands
                              (list (schema-command
                                     'unknown-reference
                                     (list (schema-parameter
                                            'value
                                            (reference-type 'Missing)))
                                     Unit
                                     '())))))
(check-exn exn:fail:contract?
           (lambda ()
             (make-app-schema "org.racket.bad" 1
                              #:events (list (schema-event 'bad Unit)))))
(check-exn exn:fail:contract?
           (lambda () (make-app-schema "not portable/id" 1)))
(check-exn exn:fail:contract?
           (lambda () (make-app-schema "org.racket.too-new" (expt 2 63))))
