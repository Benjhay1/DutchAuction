;; Title: Dutch Auction for NFTs
;; Description: A Dutch auction contract where price decreases over time until first bid wins

;; Import NFT trait
(use-trait nft-trait .nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-EXPIRED (err u1))
(define-constant ERR-AUCTION-EXISTS (err u2))
(define-constant ERR-AUCTION-NOT-FOUND (err u3))
(define-constant ERR-UNAUTHORIZED (err u4))
(define-constant ERR-AUCTION-ENDED (err u5))
(define-constant ERR-SELF-BID (err u6))
(define-constant ERR-CONTRACT-PAUSED (err u7))
(define-constant ERR-INVALID-START-PRICE (err u8))
(define-constant ERR-INVALID-DROP-RATE (err u9))
(define-constant ERR-INVALID-DURATION (err u10))
(define-constant ERR-NO-FUNDS-TO-CLAIM (err u11))
(define-constant ERR-AUCTION-NOT-ENDED (err u12))
(define-constant ERR-INVALID-FEE (err u13))
(define-constant BLOCKS-PER-DAY u144) ;; Approximately 1 day worth of blocks

;; Data vars
(define-data-var contract-paused bool false)
(define-data-var next-auction-id uint u0)
(define-data-var protocol-fee uint u25) ;; 2.5% fee in basis points

;; Data maps
(define-map auctions
    { auction-id: uint }
    {
        seller: principal,
        nft-contract: principal,
        token-id: uint,
        start-price: uint,
        current-price: uint,
        min-price: uint,
        price-drop-rate: uint,
        start-block: uint,
        end-block: uint,
        status: (string-ascii 20),
        winner: (optional principal)
    }
)

;; Private functions
(define-private (calculate-current-price (auction-data {
        start-price: uint,
        start-block: uint,
        price-drop-rate: uint,
        min-price: uint
    }))
    (let
        (
            (blocks-passed (- block-height (get start-block auction-data)))
            (total-price-drop (* blocks-passed (get price-drop-rate auction-data)))
            (calculated-price (if (> (get start-price auction-data) total-price-drop)
                (- (get start-price auction-data) total-price-drop)
                (get min-price auction-data)))
        )
        (if (< calculated-price (get min-price auction-data))
            (get min-price auction-data)
            calculated-price)
    )
)

(define-private (calculate-protocol-fee (amount uint))
    (/ (* amount (var-get protocol-fee)) u1000)
)

;; Public functions

;; Create a new auction
(define-public (create-auction (nft-contract <nft-trait>) (token-id uint) (start-price uint) (min-price uint) (duration uint) (price-drop-rate uint))
    (begin
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (> start-price min-price) ERR-INVALID-START-PRICE)
        (asserts! (> price-drop-rate u0) ERR-INVALID-DROP-RATE)
        (asserts! (>= duration BLOCKS-PER-DAY) ERR-INVALID-DURATION)
        
        (let
            (
                (auction-id (var-get next-auction-id))
            )
            ;; Transfer NFT to contract
            (try! (contract-call? nft-contract transfer token-id tx-sender (as-contract tx-sender)))
            
            ;; Create auction
            (map-set auctions
                { auction-id: auction-id }
                {
                    seller: tx-sender,
                    nft-contract: (contract-of nft-contract),
                    token-id: token-id,
                    start-price: start-price,
                    current-price: start-price,
                    min-price: min-price,
                    price-drop-rate: price-drop-rate,
                    start-block: block-height,
                    end-block: (+ block-height duration),
                    status: "active",
                    winner: none
                }
            )
            
            ;; Increment auction ID
            (var-set next-auction-id (+ auction-id u1))
            
            (ok auction-id)
        )
    )
)

;; Place a bid (automatic win if price is met)
(define-public (place-bid (auction-id uint) (nft-contract <nft-trait>))
    (let
        (
            (auction (unwrap! (map-get? auctions {auction-id: auction-id}) ERR-AUCTION-NOT-FOUND))
            (current-price (calculate-current-price {
                start-price: (get start-price auction),
                start-block: (get start-block auction),
                price-drop-rate: (get price-drop-rate auction),
                min-price: (get min-price auction)
            }))
        )
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (is-eq (get status auction) "active") ERR-AUCTION-ENDED)
        (asserts! (<= block-height (get end-block auction)) ERR-AUCTION-ENDED)
        (asserts! (not (is-eq tx-sender (get seller auction))) ERR-SELF-BID)
        (asserts! (is-eq (contract-of nft-contract) (get nft-contract auction)) ERR-UNAUTHORIZED)
        
        ;; Transfer payment
        (try! (stx-transfer? current-price tx-sender (as-contract tx-sender)))
        
        ;; Update auction
        (map-set auctions
            { auction-id: auction-id }
            (merge auction {
                current-price: current-price,
                status: "ended",
                winner: (some tx-sender)
            })
        )
        
        ;; Transfer NFT to winner
        (try! (as-contract
            (contract-call? nft-contract
                transfer
                (get token-id auction)
                (as-contract tx-sender)
                tx-sender)))
        
        (ok current-price)
    )
)

;; Claim funds (for seller)
(define-public (claim-funds (auction-id uint))
    (let
        (
            (auction (unwrap! (map-get? auctions {auction-id: auction-id}) ERR-AUCTION-NOT-FOUND))
            (fee (calculate-protocol-fee (get current-price auction)))
            (seller-amount (- (get current-price auction) fee))
        )
        
        (asserts! (is-eq tx-sender (get seller auction)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status auction) "ended") ERR-AUCTION-NOT-ENDED)
        (asserts! (is-some (get winner auction)) ERR-NO-FUNDS-TO-CLAIM)
        
        ;; Transfer funds to seller
        (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller auction))))
        
        ;; Transfer fee to contract owner
        (try! (as-contract (stx-transfer? fee tx-sender contract-owner)))
        
        (ok true)
    )
)

;; Cancel auction (only if no bids and auction is active)
(define-public (cancel-auction (auction-id uint) (nft-contract <nft-trait>))
    (let
        (
            (auction (unwrap! (map-get? auctions {auction-id: auction-id}) ERR-AUCTION-NOT-FOUND))
        )
        
        (asserts! (is-eq tx-sender (get seller auction)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status auction) "active") ERR-AUCTION-ENDED)
        (asserts! (is-eq (contract-of nft-contract) (get nft-contract auction)) ERR-UNAUTHORIZED)
        
        ;; Return NFT to seller
        (try! (as-contract 
            (contract-call? nft-contract
                transfer 
                (get token-id auction)
                (as-contract tx-sender)
                (get seller auction))))
        
        ;; Update auction status
        (map-set auctions
            { auction-id: auction-id }
            (merge auction { status: "cancelled" })
        )
        
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-auction (auction-id uint))
    (map-get? auctions { auction-id: auction-id })
)

(define-read-only (get-current-auction-price (auction-id uint))
    (match (map-get? auctions { auction-id: auction-id })
        auction (ok (calculate-current-price {
            start-price: (get start-price auction),
            start-block: (get start-block auction),
            price-drop-rate: (get price-drop-rate auction),
            min-price: (get min-price auction)
        }))
        ERR-AUCTION-NOT-FOUND
    )
)

;; Admin functions

(define-public (set-protocol-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (<= new-fee u100) ERR-INVALID-FEE)
        (var-set protocol-fee new-fee)
        (ok true)
    )
)

(define-public (toggle-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)