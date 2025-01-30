# Dutch Auction NFT Marketplace

A decentralized Dutch auction system for NFTs built on Stacks blockchain using Clarity smart contracts. In this system, auction prices automatically decrease over time until a buyer makes a purchase.

## Overview

Dutch auctions are price discovery mechanisms where the price starts high and gradually decreases until a buyer accepts the current price. This implementation is specifically designed for NFT sales with the following features:

- Automated price reduction based on block height
- Instant settlement when bid meets current price
- Built-in royalty/fee system
- Emergency pause functionality
- Secure NFT transfer handling

## Project Structure

```
dutch-auction-nft/
├── contracts/
│   ├── dutch-auction.clar    # Main auction contract
│   ├── nft-trait.clar        # NFT trait definition
│   └── error-codes.clar      # Centralized error codes
├── tests/
│   ├── dutch-auction_test.ts # Main test file
│   └── helpers.ts            # Test helper functions
├── scripts/
│   ├── deploy.ts             # Deployment script
│   └── setup-auction.ts      # Auction setup helpers
├── frontend/                 # (Optional) Frontend implementation
├── README.md
└── package.json
```

## Smart Contracts

### 1. dutch-auction.clar
The main contract implementing the Dutch auction logic with the following key features:
- Create and manage auctions
- Handle bidding and settlement
- Manage funds distribution
- Administrative functions

### 2. nft-trait.clar
Defines the standard interface that NFTs must implement to be compatible with the auction system:
- Transfer functionality
- Ownership verification
- Token metadata access

### 3. error-codes.clar
Centralizes error handling across contracts with organized error categories:
- Core contract errors
- Auction configuration errors
- Bidding errors
- NFT operation errors
- Settlement errors

## Key Features

1. **Auction Creation**
   - Set starting price
   - Define minimum price
   - Configure price decrease rate
   - Set auction duration

2. **Price Mechanism**
   - Linear price reduction over time
   - Price floor protection
   - Automatic price calculation based on block height

3. **Security Features**
   - Safe NFT transfers
   - Protected admin functions
   - Emergency pause capability
   - Comprehensive error handling

4. **Fee System**
   - Configurable protocol fee
   - Automatic fee distribution
   - Secure fund management

## Usage

### Creating an Auction

```clarity
(contract-call? .dutch-auction create-auction
    nft-contract      ;; NFT contract implementing nft-trait
    token-id         ;; ID of the NFT to auction
    start-price      ;; Initial price in STX
    min-price        ;; Minimum acceptable price
    duration         ;; Auction duration in blocks
    price-drop-rate  ;; Price decrease per block
)
```

### Placing a Bid

```clarity
(contract-call? .dutch-auction place-bid 
    auction-id       ;; ID of the auction
    nft-contract     ;; NFT contract reference
)
```

### Claiming Funds (Seller)

```clarity
(contract-call? .dutch-auction claim-funds
    auction-id       ;; ID of the auction
)
```

## Installation

1. Clone the repository
```bash
git clone <repository-url>
cd dutch-auction-nft
```

2. Install dependencies
```bash
npm install
```

3. Run tests
```bash
npm test
```

## Development

1. Local Development
```bash
clarinet console
```

2. Testing
```bash
clarinet test
```

3. Deployment
```bash
clarinet deploy
```

## Security Considerations

- All NFT transfers are handled through secure contract calls
- Price calculations are done on-chain
- Admin functions are protected
- Emergency pause mechanism available
- Comprehensive error handling

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request