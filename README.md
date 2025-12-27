# FMAO Book Tokens - Setup Guide

## Project Structure

```
fmao-book-tokens/
├── src/
│   └── FMAOBookTokens.sol          # Main contract
├── script/
│   ├── DeployFMAOBookTokens.s.sol  # Deployment scripts
│   └── Interactions.s.sol          # Interaction scripts
├── test/
│   └── FMAOBookTokens.t.sol        # Test suite
├── scripts/                         # Bash helper scripts
│   ├── deploy.sh                    # Deploy selected network (Base Sepolia and Mainnet supported)
│   ├── create-book.sh               # Create new book
│   ├── update-base-uri.sh           # Update metadata URI
│   ├── mint-book.sh                 # Mint tokens (testing)
│   ├── withdraw.sh                  # Withdraw funds
│   ├── view-info.sh                 # View contract info
│   └── check-balance.sh             # Check user balance
├── .env                             # Environment variables (create this)
├── foundry.toml                     # Foundry config
└── README.md
```

---

## Initial Setup

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Create Project Directory

```bash
mkdir fmao-book-tokens
cd fmao-book-tokens
forge init --no-commit
```

### 3. Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

### 4. Create Environment File

Create `.env` in project root from `.env.example` file

**Important**: Don't remove `.env` from `.gitignore`!

### 5. Enable Main Script and Scripts Directory

```bash
chmod +x scripts.sh scripts/*.sh  # Make all scripts executable
```

---

## Quick Start

### Option A: Using the All-in-One Script

```bash
# Source the functions
source scripts.sh

# Deploy to select network
deploy

# Check current contract information
view_info

# View help for all commands
help
```

### Option B: Using Individual Scripts

```bash
# Deploy to select network
./scripts/deploy.sh

# Check current contract information
./scripts/view-info.sh

# Create first book
./scripts/create-book.sh 0
```

---

## Deployment Workflow

### Testnet Deployment (Base Sepolia)

#### Step 1: Deploy Contract
```bash
# Taget Network set to Sepolia by default on .env.example
./scripts/deploy.sh
```

After deployment:
- Copy the contract address
- Update `CONTRACT_ADDRESS` in `.env`
- Verify on BaseScan: `https://sepolia.basescan.org/address/YOUR_ADDRESS`

#### Step 2: Prepare Metadata
1. Create `metadata/0.json` with your Book 0 metadata
2. Upload folder to IPFS
3. Get the CID (e.g., `QmXyZ789`)
4. Update `NEW_BASE_URI=ipfs://QmXyZ789/` in `.env`

#### Step 3: Update Base URI
```bash
./scripts/update-base-uri.sh
```

#### Step 4: Create Book 0
```bash
./scripts/create-book.sh 0
```

#### Step 5: Verify Everything
```bash
./scripts/view-info.sh
```

You should see:
- Book 0 exists: true
- Metadata URI: `ipfs://QmXyZ789/0.json`

#### Step 6: Test Minting
```bash
./scripts/mint-book.sh 0 1
```

---

### Mainnet Deployment (Base)

**⚠️ Only deploy to mainnet when you're 100% ready!**

#### Step 1: Change Target Network on .env

```bash
# Network selection: 'sepolia' or 'mainnet'
TARGET_NETWORK=mainnet
```

#### Step 2: Deploy Contract

```bash
# Make sure everything is tested on Sepolia first!
./scripts/deploy.sh
```

---

## Adding New Books

When you're ready to release Book 1:

### Step 1: Update Metadata Folder
1. Add `1.json` to your existing metadata folder
2. Re-upload entire folder to IPFS (must include `0.json` AND `1.json`)
3. Get new CID
4. Update `NEW_BASE_URI` in `.env`

### Step 2: Update Base URI
```bash
./scripts/update-base-uri.sh
```

### Step 3: Create Book 1
```bash
./scripts/create-book.sh 1
```

### Step 4: Verify
```bash
./scripts/view-info.sh
```

---

## Testing

### Run All Tests
```bash
forge test -vvv
```

### Run Specific Test
```bash
forge test --match-test test_MintBook -vvvv
```

### Gas Report
```bash
forge test --gas-report
```

### Coverage Report
```bash
forge coverage
```

---

## Common Operations

### Check Contract Info
```bash
./scripts/view-info.sh
```

### Check User Balance
```bash
./scripts/check-balance.sh 0x1234...
```

### Withdraw Funds
```bash
./scripts/withdraw.sh
```

### Mint Books
```bash
# Mint 1 copy of Book 0
./scripts/mint-book.sh 0 1

# Mint 5 copies of Book 1
./scripts/mint-book.sh 1 5
```

---

## Troubleshooting

### "Contract not verified"
Wait a few minutes after deployment, then check BaseScan. If still not verified, manually verify:
```bash
forge verify-contract \
    --chain-id 84532 \
    --constructor-args $(cast abi-encode "constructor(address,string)" YOUR_ADDRESS "ipfs://...") \
    YOUR_CONTRACT_ADDRESS \
    src/FMAOBookTokens.sol:FMAOBookTokens
```

### "Insufficient funds for gas"
Make sure your deployer wallet has Base Sepolia ETH:
- Get testnet ETH from Base Sepolia faucet
- Mainnet: ensure you have enough ETH for gas

### "Book ID must be sequential"
You must create books in order: 0, 1, 2, 3...
You can't skip numbers or create them out of order.

### "Book does not exist"
You need to call `createBook()` before anyone can mint that book.

---

## Security Disclaimer

This contract has **not been formally audited** by a third-party security firm. While the code has been thoroughly tested on Sepolia testnet and reviewed for common vulnerabilities, it may still contain bugs or security issues.

**Use at your own risk.** If you intend to deploy this contract with real assets or significant value:

- Consider getting a formal security audit from a reputable firm
- Deploy on testnet first and thoroughly test with your use case
- Have the contract reviewed by experienced Solidity developers
- Use conservative assumptions about potential vulnerabilities
- Consider implementing gradual rollout and monitoring strategies

The authors and contributors are not responsible for any losses or damages resulting from the use of this code.

---

## License

MIT License - see LICENSE file for details

---

**Built by lokapal.eth**