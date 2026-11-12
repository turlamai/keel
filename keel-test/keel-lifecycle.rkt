#lang racket/base

(require rackunit
         "../keel/main.rkt")

(check-equal? lifecycle-initial-state 'starting)
(for ([state (in-list lifecycle-states)])
  (check-true (lifecycle-state? state)))
(check-false (lifecycle-state? 'failed))
(check-true (lifecycle-terminal-state? 'stopped))
(check-false (lifecycle-terminal-state? 'running))

(for ([transition (in-list '((starting ready)
                             (starting stopping)
                             (ready running)
                             (ready stopping)
                             (running stopping)
                             (stopping stopped)))])
  (check-true (apply lifecycle-transition? transition)))

(for ([transition (in-list '((starting running)
                             (ready stopped)
                             (running ready)
                             (stopped starting)
                             (stopped stopped)))])
  (check-false (apply lifecycle-transition? transition)))

(for ([outcome (in-list request-terminal-outcomes)])
  (check-true (request-terminal-outcome? outcome)))
(check-false (request-terminal-outcome? 'pending))
