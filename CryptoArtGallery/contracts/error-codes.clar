;; Title: Error Codes for Dutch Auction System
;; Description: Centralized error codes and messages for the Dutch Auction NFT marketplace

;; Core Contract Error Codes (1xx)
(define-constant ERR-NOT-INITIALIZED (err u100))
(define-constant ERR-CONTRACT-PAUSED (err u101))
(define-constant ERR-UNAUTHORIZED (err u102))
(define-constant ERR-ALREADY-INITIALIZED (err u103))

;; Auction Creation & Configuration Errors (2xx)
(define-constant ERR-INVALID-START-PRICE (err u200))
(define-constant ERR-INVALID-MIN-PRICE (err u201))
(define-constant ERR-INVALID-DURATION (err u202))
(define-constant ERR-INVALID-DROP-RATE (err u203))
(define-constant ERR-START-PRICE-BELOW-MIN (err u204))
(define-constant ERR-AUCTION-EXISTS (err u205))
(define-constant ERR-ZERO-PRICE (err u206))

;; Auction State Errors (3xx)
(define-constant ERR-AUCTION-NOT-FOUND (err u300))
(define-constant ERR-AUCTION-ENDED (err u301))
(define-constant ERR-AUCTION-NOT-ENDED (err u302))
(define-constant ERR-AUCTION-CANCELED (err u303))
(define-constant ERR-AUCTION-ACTIVE (err u304))

;; Bidding Errors (4xx)
(define-constant ERR-PRICE-TOO-LOW (err u400))
(define-constant ERR-INSUFFICIENT-FUNDS (err u401))
(define-constant ERR-SELF-BID (err u402))
(define-constant ERR-INVALID-BID (err u403))

;; NFT Related Errors (5xx)
(define-constant ERR-NFT-TRANSFER-FAILED (err u500))
(define-constant ERR-NFT-NOT-OWNED (err u501))
(define-constant ERR-INVALID-NFT-CONTRACT (err u502))
(define-constant ERR-TOKEN-NOT-FOUND (err u503))

;; Settlement Errors (6xx)
(define-constant ERR-ALREADY-CLAIMED (err u600))
(define-constant ERR-NOT-WINNER (err u601))
(define-constant ERR-PAYMENT-FAILED (err u602))
(define-constant ERR-NO-FUNDS-TO-CLAIM (err u603))

;; Helper Functions

;; Function to convert error codes to human-readable messages
(define-read-only (get-error-message (code uint))
    (if (is-eq code u100)
        "Contract is not initialized"
        (if (is-eq code u101)
            "Contract is currently paused"
            (if (is-eq code u102)
                "Unauthorized operation"
                (if (is-eq code u103)
                    "Contract is already initialized"
                    (if (is-eq code u200)
                        "Invalid start price"
                        (if (is-eq code u201)
                            "Invalid minimum price"
                            "Unknown error code"
                        )
                    )
                )
            )
        )
    )
)

;; Function to check if an error code is related to auction configuration
(define-read-only (is-config-error (code uint))
    (and (>= code u200) (<= code u299))
)

;; Function to check if an error code is related to bidding
(define-read-only (is-bidding-error (code uint))
    (and (>= code u400) (<= code u499))
)

;; Function to check if an error code is related to NFT operations
(define-read-only (is-nft-error (code uint))
    (and (>= code u500) (<= code u599))
)

;; Function to check if an error is recoverable
(define-read-only (is-recoverable-error (code uint))
    (or 
        (is-bidding-error code)
        (is-eq code u602)  ;; Payment failed
        (is-eq code u500)  ;; NFT transfer failed
    )
)