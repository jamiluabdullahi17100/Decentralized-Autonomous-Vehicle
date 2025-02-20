;; Vehicle Registration Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_REGISTERED (err u409))

;; Define vehicle statuses
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_INACTIVE u2)
(define-constant STATUS_MAINTENANCE u3)

;; Data Maps
(define-map vehicles
  { vehicle-id: uint }
  {
    owner: principal,
    model: (string-ascii 50),
    license-plate: (string-ascii 20),
    status: uint,
    registration-date: uint
  }
)

(define-map license-to-id
  { license-plate: (string-ascii 20) }
  { vehicle-id: uint }
)

(define-data-var vehicle-nonce uint u0)

;; Functions
(define-public (register-vehicle (model (string-ascii 50)) (license-plate (string-ascii 20)))
  (let
    ((new-vehicle-id (+ (var-get vehicle-nonce) u1)))
    (asserts! (is-none (map-get? license-to-id { license-plate: license-plate })) ERR_ALREADY_REGISTERED)
    (map-set vehicles
      { vehicle-id: new-vehicle-id }
      {
        owner: tx-sender,
        model: model,
        license-plate: license-plate,
        status: STATUS_ACTIVE,
        registration-date: block-height
      }
    )
    (map-set license-to-id
      { license-plate: license-plate }
      { vehicle-id: new-vehicle-id }
    )
    (var-set vehicle-nonce new-vehicle-id)
    (ok new-vehicle-id)
  )
)

(define-public (update-vehicle-status (vehicle-id uint) (new-status uint))
  (let
    ((vehicle (unwrap! (get-vehicle vehicle-id) ERR_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get owner vehicle)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (or (is-eq new-status STATUS_ACTIVE) (is-eq new-status STATUS_INACTIVE) (is-eq new-status STATUS_MAINTENANCE)) ERR_NOT_AUTHORIZED)
    (ok (map-set vehicles
      { vehicle-id: vehicle-id }
      (merge vehicle { status: new-status })
    ))
  )
)

(define-read-only (get-vehicle (vehicle-id uint))
  (map-get? vehicles { vehicle-id: vehicle-id })
)

(define-read-only (get-vehicle-by-license-plate (license-plate (string-ascii 20)))
  (match (map-get? license-to-id { license-plate: license-plate })
    id (get-vehicle (get vehicle-id id))
    none
  )
)

(define-read-only (get-total-vehicles)
  (ok (var-get vehicle-nonce))
)

