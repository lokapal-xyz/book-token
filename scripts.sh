#!/bin/bash

# =============================================================================
# FMAO Book Tokens - Deployment & Interaction Scripts
# =============================================================================
# Usage: source this file or copy individual functions to separate files
# Make sure to set your .env file with required variables first
# =============================================================================

set -e  # Exit on error

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Configuration: Select RPC based on TARGET_NETWORK
if [ "$TARGET_NETWORK" == "mainnet" ]; then
    RPC_URL=$BASE_MAINNET_RPC_URL
    NETWORK_NAME="Base Mainnet"
    CONFIRM_REQUIRED=true
else
    RPC_URL=$BASE_SEPOLIA_RPC_URL
    NETWORK_NAME="Base Sepolia"
    CONFIRM_REQUIRED=false
fi

# Helper function for safety
confirm_action() {
    if [ "$CONFIRM_REQUIRED" = true ]; then
        echo -e "\033[1;33m[WARNING]\033[0m You are targeting $NETWORK_NAME."
        read -p "Are you sure you want to proceed? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi
}

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# =============================================================================
# DEPLOYMENT SCRIPTS
# =============================================================================

deploy() {
    confirm_action
    echo -e "Deploying to $NETWORK_NAME..."
    
    forge script script/DeployFMAOBookTokens.s.sol:DeployFMAOBookTokens \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        -vvvv

    print_success "Deployment complete!"
    print_warning "Don't forget to:"
    echo "  1. Update CONTRACT_ADDRESS in .env"
    echo "  2. Upload metadata to IPFS"
    echo "  3. Run update_base_uri"
    echo "  4. Run create_book 0"
}

# =============================================================================
# OWNER INTERACTION SCRIPTS
# =============================================================================

# Update base metadata URI
update_base_uri() {
    if [ -z "$CONTRACT_ADDRESS" ]; then
        print_error "CONTRACT_ADDRESS not set in .env"
        return 1
    fi
    
    if [ -z "$NEW_BASE_URI" ]; then
        print_error "NEW_BASE_URI not set in .env"
        return 1
    fi
    
    confirm_action
    echo -e "Updating base URI to: $NEW_BASE_URI"
    
    forge script script/Interactions.s.sol:UpdateBaseURI \
        --rpc-url $RPC_URL \
        --broadcast \
        -vvvv
    
    print_success "Base URI updated!"
}

# Create a new book
create_book() {
    local book_id=$1

    if [ -z "$CONTRACT_ADDRESS" ]; then
        print_error "CONTRACT_ADDRESS not set in .env"
        return 1
    fi
    
    if [ -z "$book_id" ]; then
        print_error "Usage: create_book <book_id>"
        return 1
    fi
    
    confirm_action
    echo -e "Creating Book $book_id on $NETWORK_NAME..."
    
    BOOK_ID=$book_id forge script script/Interactions.s.sol:CreateBook \
        --rpc-url $RPC_URL \
        --broadcast \
        -vvvv

    print_success "Book $book_id created!"
}


# Withdraw contract funds to owner
withdraw() {
    if [ -z "$CONTRACT_ADDRESS" ]; then
        print_error "CONTRACT_ADDRESS not set in .env"
        return 1
    fi
    
    confirm_action
    echo -e "Withdrawing funds from contract on $NETWORK_NAME..."
    
    forge script script/Interactions.s.sol:Withdraw \
        --rpc-url $RPC_URL \
        --broadcast \
        -vvvv
    
    print_success "Withdrawal complete!"
}


# Mint book tokens
mint_book() {
    local book_id=$1
    local amount=$2

    if [ -z "$CONTRACT_ADDRESS" ]; then
        print_error "CONTRACT_ADDRESS not set in .env"
        return 1
    fi
    
    if [ -z "$book_id" ] || [ -z "$amount" ]; then
        print_error "Usage: mint_book <book_id> <amount>"
        return 1
    fi
    
    confirm_action
    echo -e "Minting $amount of Book $book_id on $NETWORK_NAME..."
    
    BOOK_ID=$book_id MINT_AMOUNT=$amount forge script script/Interactions.s.sol:MintBook \
        --rpc-url $RPC_URL \
        --broadcast \
        -vvvv

    print_success "Minted successfully!"
}


# =============================================================================
# VIEW FUNCTIONS (NO TRANSACTION)
# =============================================================================

# View contract information
view_info() {
    if [ -z "$CONTRACT_ADDRESS" ]; then
        print_error "CONTRACT_ADDRESS not set in .env"
        return 1
    fi

    echo -e "Fetching info from $NETWORK_NAME..."
    forge script script/Interactions.s.sol:ViewInfo \
        --rpc-url $RPC_URL \
        -vvvv
}


# Check user balance
check_balance() {
    local user_address=$1
    
    if [ -z "$CONTRACT_ADDRESS" ]; then
        print_error "CONTRACT_ADDRESS not set in .env"
        return 1
    fi
    
    if [ -z "$user_address" ]; then
        print_error "Usage: check_balance <user_address>"
        return 1
    fi
    
    print_status "Checking balances for $user_address from $NETWORK_NAME..."
    echo ""
    
    USER_ADDRESS=$user_address forge script script/Interactions.s.sol:CheckBalance \
        --rpc-url $RPC_URL \
        -vvvv
}


# Show help
help() {
    echo -e "${BLUE}FMAO Book Tokens - Command Interface${NC}"
    echo "======================================"
    echo -e "Current Target: ${YELLOW}$NETWORK_NAME${NC}"
    echo "======================================"
    echo ""
    echo "DEPLOYMENT:"
    echo "  deploy                      - Deploy to the current target network"
    echo ""
    echo "OWNER FUNCTIONS (Requires Owner Private Key):"
    echo "  update_base_uri             - Sync contract metadata with NEW_BASE_URI"
    echo "  create_book <id>            - Initialize a new Book ID on-chain"
    echo "  withdraw                    - Pull contract balance to owner wallet"
    echo ""
    echo "USER & TESTING FUNCTIONS:"
    echo "  mint_book <id> <qty>        - Mint copies of a specific book"
    echo "  view_info                   - Read contract state (Base URI, Owner, etc.)"
    echo "  check_balance <address>     - Check how many books a user owns"
    echo ""
    echo "GLOBAL SETTINGS:"
    echo "  To change networks, update 'TARGET_NETWORK' in your .env file."
    echo "  Supported values: 'sepolia', 'mainnet'"
    echo ""
    echo "EXAMPLE:"
    echo "  create_book 0               - Registers 'Book 0' on $NETWORK_NAME"
    echo ""
}

# Show help by default if sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    help
fi