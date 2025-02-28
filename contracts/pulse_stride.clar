;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-challenge (err u101))
(define-constant err-already-joined (err u102))
(define-constant err-challenge-ended (err u103))
(define-constant err-invalid-steps (err u104))

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
    completed: bool
  }
)

;; Challenge counter
(define-data-var challenge-counter uint u0)

;; Public functions
(define-public (create-challenge (name (string-ascii 100)) (target-steps uint) (duration-days uint))
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
    (ok new-id)
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
        completed: false
      }
    )
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
    
    (map-set participants
      { challenge-id: challenge-id, user: tx-sender }
      {
        total-steps: (+ (get total-steps participant) steps),
        joined-height: (get joined-height participant),
        completed: (>= (+ (get total-steps participant) steps) (get target-steps challenge))
      }
    )
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-challenge (challenge-id uint))
  (map-get? challenges { challenge-id: challenge-id })
)

(define-read-only (get-participant (challenge-id uint) (user principal))
  (map-get? participants { challenge-id: challenge-id, user: user })
)

(define-read-only (get-progress (challenge-id uint) (user principal))
  (let ((participant (unwrap! (get-participant challenge-id user) err-invalid-challenge)))
    (ok (get total-steps participant))
  )
)

(define-read-only (is-active (challenge-id uint))
  (let ((challenge (unwrap! (get-challenge challenge-id) err-invalid-challenge)))
    (< block-height (+ (get start-height challenge) (* (get duration-days challenge) u144)))
  )
)
