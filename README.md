# PulseStride
A decentralized walking challenge app that connects users globally for virtual marathons and steps competitions on the Stacks blockchain.

## Features
- Create and join walking challenges
- Record daily steps and view progress
- Participate in global virtual marathons
- Earn rewards for completing challenges
- View leaderboards and rankings

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new challenge
(contract-call? .pulse-stride create-challenge "Global Marathon" u1000000 u30)

;; Join a challenge
(contract-call? .pulse-stride join-challenge u1)

;; Record daily steps
(contract-call? .pulse-stride record-steps u1 u10000)

;; Get challenge progress
(contract-call? .pulse-stride get-progress u1 tx-sender)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
