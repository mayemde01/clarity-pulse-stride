;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-challenge (err u101))
(define-constant err-already-joined (err u102))
(define-constant err-challenge-ended (err u103))
(define-constant err-invalid-steps (err u104))
(define-constant err-invalid-duration (err u105))
(define-constant err-zero-value (err u106))

;; Data structures
(define-map challenges
  { challenge-id: uint }
  {
    name: (string-ascii 100),
    target-steps: uint,
    duration-days: uint,
    start-height: uint,
    creator: principal,
    active: bool
  }
)

(define-map participants
  { challenge-id: uint, user: principal }
  { 
    total-steps: uint,
    joined-height: uint,
    completed: bool,
    last-record-height: uint
  }
)

;; Challenge counter
(define-data-var challenge-counter uint u0)

;; Events
(define-public (print-event (event-type (string-ascii 50)) (challenge-id uint))
  (ok (print { event-type: event-type, challenge-id: challenge-id, user: tx-sender }))
)

;; Public functions
(define-public (create-challenge (name (string-ascii 100)) (target-steps uint) (duration-days uint))
  (begin
    (asserts! (> duration-days u0) err-invalid-duration)
    (asserts! (> target-steps u0) err-zero-value)
    (let ((new-id (+ (var-get challenge-counter) u1)))
      (map-set challenges
        { challenge-id: new-id }
        {
          name: name,
          target-steps: target-steps,
          duration-days: duration-days,
          start-height: block-height,
          creator: tx-sender,
          active: true
        }
      )
      (var-set challenge-counter new-id)
      (print-event "challenge-created" new-id)
      (ok new-id)
    )
  )
)

(define-public (deactivate-challenge (challenge-id uint))
  (let ((challenge (unwrap! (get-challenge challenge-id) err-invalid-challenge)))
    (asserts! (is-eq (get creator challenge) tx-sender) err-owner-only)
    (map-set challenges
      { challenge-id: challenge-id }
      (merge challenge { active: false })
    )
    (print-event "challenge-deactivated" challenge-id)
    (ok true)
  )
)

(define-public (join-challenge (challenge-id uint))
  (let ((challenge (unwrap! (get-challenge challenge-id) err-invalid-challenge)))
    (asserts! (is-active challenge-id) err-challenge-ended)
    (asserts! (is-none (get-participant challenge-id tx-sender)) err-already-joined)
    
    (map-set participants
      { challenge-id: challenge-id, user: tx-sender }
      {
        total-steps: u0,
        joined-height: block-height,
        completed: false,
        last-record-height: block-height
      }
    )
    (print-event "challenge-joined" challenge-id)
    (ok true)
  )
)

(define-public (record-steps (challenge-id uint) (steps uint))
  (let (
    (challenge (unwrap! (get-challenge challenge-id) err-invalid-challenge))
    (participant (unwrap! (get-participant challenge-id tx-sender) err-invalid-challenge))
  )
    (asserts! (is-active challenge-id) err-challenge-ended)
    (asserts! (< steps u100000) err-invalid-steps)
    (asserts! (> steps u0) err-zero-value)
    (asserts! (>= block-height (get last-record-height participant)) err-invalid-steps)
    
    (map-set participants
      { challenge-id: challenge-id, user: tx-sender }
      {
        total-steps: (+ (get total-steps participant) steps),
        joined-height: (get joined-height participant),
        completed: (>= (+ (get total-steps participant) steps) (get target-steps challenge)),
        last-record-height: block-height
      }
    )
    (print-event "steps-recorded" challenge-id)
    (ok true)
  )
)

;; Read only functions remain unchanged
[... existing read-only functions ...]
