;; Title: NFT Trait Interface for Dutch Auction
;; Description: Defines the standard interface that NFTs must implement to be compatible with the Dutch Auction contract

(define-trait nft-trait (
    ;; Transfer the NFT from one principal to another
    (transfer (uint principal principal) (response bool uint))

    ;; Get the owner of a specific NFT
    (get-owner (uint) (response principal uint))

    ;; Get the last token ID minted
    (get-last-token-id () (response uint uint))

    ;; Check if a token ID exists
    (token-exists (uint) (response bool uint))

    ;; Get the token URI
    (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
))

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-TOKEN-NOT-FOUND (err u101))
(define-constant ERR-TOKEN-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-RECIPIENT (err u103))