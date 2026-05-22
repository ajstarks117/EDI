# TravelTrek Blockchain & Identity Layer

This module manages the blockchain digital identity system for tourists. It includes the Solidity smart contracts, compilation configurations, testing setups, and migration scripts.

## 📂 Project Structure

```text
contracts/
└── TouristIdentity.sol     # Digital KYC registration and visa validity smart contract
scripts/
└── deploy.js               # Contract deployment automation
hardhat.config.js           # Compilation options and RPC endpoints configuration
```

---

## 🏗️ Solidity Smart Contract: `TouristIdentity`

The contract is designed to store tamper-proof travel registration details. It supports:
1. **System Administrator**: Full authorization authority management (typically assigned to Tourism Authorities or Immigration).
2. **Authorized Agents**: Police outposts and registry desks that can add or revoke tourist records.
3. **Tourist KYC Metadata**: Standardized storage for name, nationality, and encrypted IPFS file credentials hashes containing visas and health indicators.

---

## 🚀 Execution Guide

1. Install hardhat workspace requirements:
   ```bash
   npm install
   ```
2. Compile smart contracts:
   ```bash
   npm run compile
   ```
3. Boot up the local testnet node (Hardhat network):
   ```bash
   npm run node
   ```
4. Deploy contracts to the local network:
   ```bash
   npm run deploy:local
   ```
