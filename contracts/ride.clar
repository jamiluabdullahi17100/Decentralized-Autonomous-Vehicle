;; Ride Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_STATUS (err u400))

;; Define ride statuses
(define-constant STATUS_REQUESTED u1)
(define-constant STATUS_ACCEPTED u2)
(define-constant STATUS_IN_PROGRESS u3)
(define-constant STATUS_COMPLETED u4)
(define-constant STATUS_CANCELLED u5)

;; Data Maps
(define-map rides
  { ride-id: uint }
  {
    passenger: principal,
    vehicle-id: uint,
    pickup-location: (string-ascii 100),
    dropoff-location: (string-ascii 100),
    status: uint,
    request-time: uint,
    completion-time: (optional uint),
    fare: uint
  }
)

(define-data-var ride-nonce uint u0)

;; Functions
(define-public (request-ride (pickup-location (string-ascii 100)) (dropoff-location (string-ascii 100)))
  (let
    ((new-ride-id (+ (var-get ride-nonce) u1)))
    (map-set rides
      { ride-id: new-ride-id }
      {
        passenger: tx-sender,
        vehicle-id: u0,
        pickup-location: pickup-location,
        dropoff-location: dropoff-location,
        status: STATUS_REQUESTED,
        request-time: block-height,
        completion-time: none,
        fare: u0
      }
    )
    (var-set ride-nonce new-ride-id)
    (ok new-ride-id)
  )
)

(define-public (accept-ride (ride-id uint) (vehicle-id uint))
  (let
    ((ride (unwrap! (map-get? rides { ride-id: ride-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status ride) STATUS_REQUESTED) ERR_INVALID_STATUS)
    (ok (map-set rides
      { ride-id: ride-id }
      (merge ride { vehicle-id: vehicle-id, status: STATUS_ACCEPTED })
    ))
  )
)

(define-public (start-ride (ride-id uint))
  (let
    ((ride (unwrap! (get-ride ride-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status ride) STATUS_ACCEPTED) ERR_INVALID_STATUS)
    (ok (map-set rides
      { ride-id: ride-id }
      (merge ride { status: STATUS_IN_PROGRESS })
    ))
  )
)

(define-public (complete-ride (ride-id uint) (fare uint))
  (let
    ((ride (unwrap! (get-ride ride-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status ride) STATUS_IN_PROGRESS) ERR_INVALID_STATUS)
    (ok (map-set rides
      { ride-id: ride-id }
      (merge ride { status: STATUS_COMPLETED, completion-time: (some block-height), fare: fare })
    ))
  )
)

(define-public (cancel-ride (ride-id uint))
  (let
    ((ride (unwrap! (get-ride ride-id) ERR_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get passenger ride)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (or (is-eq (get status ride) STATUS_REQUESTED) (is-eq (get status ride) STATUS_ACCEPTED)) ERR_INVALID_STATUS)
    (ok (map-set rides
      { ride-id: ride-id }
      (merge ride { status: STATUS_CANCELLED })
    ))
  )
)

(define-read-only (get-ride (ride-id uint))
  (map-get? rides { ride-id: ride-id })
)

(define-read-only (get-rides-by-passenger (passenger principal))
  (ok (var-get ride-nonce))
)

(define-read-only (get-rides-by-vehicle (vehicle-id uint))
  (ok (var-get ride-nonce))
)

