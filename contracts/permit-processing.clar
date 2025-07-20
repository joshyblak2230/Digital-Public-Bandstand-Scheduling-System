;; Permit Processing Contract
;; Issues permits for amplified music events

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-APPLICATION (err u301))
(define-constant ERR-PERMIT-NOT-FOUND (err u302))
(define-constant ERR-INVALID-DECIBEL-LEVEL (err u303))
(define-constant ERR-PERMIT-EXPIRED (err u304))
(define-constant ERR-APPLICATION-PENDING (err u305))

;; Data Variables
(define-data-var next-permit-id uint u1)
(define-data-var permit-fee uint u25)
(define-data-var max-decibel-level uint u85)

;; Data Maps
(define-map permits
  { permit-id: uint }
  {
    applicant: principal,
    event-type: (string-ascii 50),
    event-date: uint,
    max-decibels: uint,
    status: (string-ascii 20),
    issued-at: uint,
    expires-at: uint
  }
)

(define-map permit-applications
  { application-id: uint }
  {
    applicant: principal,
    event-type: (string-ascii 50),
    event-date: uint,
    requested-decibels: uint,
    justification: (string-ascii 200),
    status: (string-ascii 20),
    submitted-at: uint
  }
)

(define-map applicant-history
  { applicant: principal }
  {
    total-permits: uint,
    violations: uint,
    last-permit: uint,
    compliance-score: uint
  }
)

;; Private Functions
(define-private (is-valid-decibel-level (decibels uint))
  (and (> decibels u0) (<= decibels (var-get max-decibel-level))))

(define-private (calculate-compliance-score (total-permits uint) (violations uint))
  (if (is-eq total-permits u0)
    u100
    (let ((violation-rate (/ (* violations u100) total-permits)))
      (if (>= violation-rate u100) u0 (- u100 violation-rate)))))

;; Public Functions
(define-public (apply-for-permit (event-type (string-ascii 50)) (event-date uint) (requested-decibels uint) (justification (string-ascii 200)))
  (let ((application-id (var-get next-permit-id)))
    (asserts! (> event-date block-height) ERR-INVALID-APPLICATION)
    (asserts! (is-valid-decibel-level requested-decibels) ERR-INVALID-DECIBEL-LEVEL)

    (map-set permit-applications
      { application-id: application-id }
      {
        applicant: tx-sender,
        event-type: event-type,
        event-date: event-date,
        requested-decibels: requested-decibels,
        justification: justification,
        status: "pending",
        submitted-at: block-height
      })

    (var-set next-permit-id (+ application-id u1))
    (ok application-id)))

(define-public (approve-permit (application-id uint) (approved-decibels uint))
  (let ((application (unwrap! (map-get? permit-applications { application-id: application-id }) ERR-PERMIT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status application) "pending") ERR-APPLICATION-PENDING)
    (asserts! (is-valid-decibel-level approved-decibels) ERR-INVALID-DECIBEL-LEVEL)

    (let ((permit-id application-id)
          (expires-at (+ (get event-date application) u86400))) ;; Expires 24 hours after event

      (map-set permits
        { permit-id: permit-id }
        {
          applicant: (get applicant application),
          event-type: (get event-type application),
          event-date: (get event-date application),
          max-decibels: approved-decibels,
          status: "active",
          issued-at: block-height,
          expires-at: expires-at
        })

      (map-set permit-applications
        { application-id: application-id }
        (merge application { status: "approved" }))

      ;; Update applicant history
      (let ((applicant (get applicant application))
            (current-history (default-to { total-permits: u0, violations: u0, last-permit: u0, compliance-score: u100 }
                                        (map-get? applicant-history { applicant: applicant }))))
        (let ((new-total (+ (get total-permits current-history) u1)))
          (map-set applicant-history
            { applicant: applicant }
            {
              total-permits: new-total,
              violations: (get violations current-history),
              last-permit: (get event-date application),
              compliance-score: (calculate-compliance-score new-total (get violations current-history))
            })))

      (ok permit-id))))

(define-public (deny-permit (application-id uint) (reason (string-ascii 100)))
  (let ((application (unwrap! (map-get? permit-applications { application-id: application-id }) ERR-PERMIT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status application) "pending") ERR-APPLICATION-PENDING)

    (map-set permit-applications
      { application-id: application-id }
      (merge application { status: "denied" }))

    (ok true)))

(define-public (revoke-permit (permit-id uint))
  (let ((permit (unwrap! (map-get? permits { permit-id: permit-id }) ERR-PERMIT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status permit) "active") ERR-PERMIT-EXPIRED)

    (map-set permits
      { permit-id: permit-id }
      (merge permit { status: "revoked" }))

    ;; Record violation
    (let ((applicant (get applicant permit))
          (current-history (unwrap! (map-get? applicant-history { applicant: applicant }) ERR-PERMIT-NOT-FOUND)))
      (let ((new-violations (+ (get violations current-history) u1))
            (total-permits (get total-permits current-history)))
        (map-set applicant-history
          { applicant: applicant }
          (merge current-history
                 { violations: new-violations,
                   compliance-score: (calculate-compliance-score total-permits new-violations) }))))

    (ok true)))

(define-public (update-max-decibel-level (new-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-level u0) ERR-INVALID-DECIBEL-LEVEL)
    (asserts! (<= new-level u120) ERR-INVALID-DECIBEL-LEVEL)
    (var-set max-decibel-level new-level)
    (ok true)))

;; Read-only Functions
(define-read-only (get-permit (permit-id uint))
  (map-get? permits { permit-id: permit-id }))

(define-read-only (get-application (application-id uint))
  (map-get? permit-applications { application-id: application-id }))

(define-read-only (get-applicant-history (applicant principal))
  (map-get? applicant-history { applicant: applicant }))

(define-read-only (is-permit-valid (permit-id uint))
  (match (map-get? permits { permit-id: permit-id })
    permit (and (is-eq (get status permit) "active")
                (> (get expires-at permit) block-height))
    false))

(define-read-only (get-permit-fee)
  (var-get permit-fee))

(define-read-only (get-max-decibel-level)
  (var-get max-decibel-level))

(define-read-only (get-next-permit-id)
  (var-get next-permit-id))
