// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { FMAOBookTokens } from "../src/FMAOBookTokens.sol";

/**
 * @title Interactions
 * @notice Helper scripts for interacting with deployed FMAOBookTokens contract
 * 
 * Set CONTRACT_ADDRESS in .env before running any interaction
 */

/**
 * @notice Update the base metadata URI
 * Usage: forge script script/Interactions.s.sol:UpdateBaseURI --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast -vvvv
 * Required .env: CONTRACT_ADDRESS, NEW_BASE_URI
 */
contract UpdateBaseURI is Script {
    function run() external {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        string memory newBaseURI = vm.envString("NEW_BASE_URI");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Updating Base URI...");
        console.log("Contract:", contractAddress);
        console.log("New Base URI:", newBaseURI);
        
        vm.startBroadcast(deployerPrivateKey);
        
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        bookTokens.setBaseURI(newBaseURI);
        
        vm.stopBroadcast();
        
        console.log("Base URI updated successfully");
    }
}

/**
 * @notice Create a new book token
 * Usage: forge script script/Interactions.s.sol:CreateBook --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast -vvvv
 * Required .env: CONTRACT_ADDRESS, BOOK_ID
 */
contract CreateBook is Script {
    function run() external {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        uint256 bookId = vm.envUint("BOOK_ID");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Creating Book...");
        console.log("Contract:", contractAddress);
        console.log("Book ID:", bookId);
        
        vm.startBroadcast(deployerPrivateKey);
        
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        bookTokens.createBook(bookId);
        
        vm.stopBroadcast();
        
        console.log("Book created successfully");
        console.log("Metadata URI:", bookTokens.uri(bookId));
        console.log("Total books:", bookTokens.bookCount());
    }
}

/**
 * @notice Mint book tokens (test minting)
 * Usage: forge script script/Interactions.s.sol:MintBook --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast -vvvv
 * Required .env: CONTRACT_ADDRESS, BOOK_ID, MINT_AMOUNT
 */
contract MintBook is Script {
    function run() external {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        uint256 bookId = vm.envUint("BOOK_ID");
        uint256 amount = vm.envUint("MINT_AMOUNT");
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        uint256 totalCost = bookTokens.BOOK_PRICE() * amount;
        
        console.log("Minting Book Tokens...");
        console.log("Contract:", contractAddress);
        console.log("User:", user);
        console.log("Book ID:", bookId);
        console.log("Amount:", amount);
        console.log("Total Cost:", totalCost);
        
        vm.startBroadcast(userPrivateKey);
        
        bookTokens.mintBook{value: totalCost}(bookId, amount);
        
        vm.stopBroadcast();
        
        console.log("Minted successfully!");
        console.log("User balance:", bookTokens.balanceOf(user, bookId));
        console.log("Total minted:", bookTokens.totalMinted(bookId));
    }
}

/**
 * @notice Mint multiple books in batch
 * Usage: forge script script/Interactions.s.sol:MintBatch --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast -vvvv
 * Hardcoded example: mints 1x Book 0 and 2x Book 1
 */
contract MintBatch is Script {
    function run() external {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        
        // Example: mint 1x Book 0 and 2x Book 1
        uint256[] memory bookIds = new uint256[](2);
        bookIds[0] = 0;
        bookIds[1] = 1;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;
        
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        uint256 totalCost = bookTokens.BOOK_PRICE() * 3; // 1 + 2 = 3 books
        
        console.log("Batch Minting...");
        console.log("Contract:", contractAddress);
        console.log("User:", user);
        console.log("Total Cost:", totalCost);
        
        vm.startBroadcast(userPrivateKey);
        
        bookTokens.mintBatch{value: totalCost}(bookIds, amounts);
        
        vm.stopBroadcast();
        
        console.log("Batch minted successfully!");
        console.log("Book 0 balance:", bookTokens.balanceOf(user, 0));
        console.log("Book 1 balance:", bookTokens.balanceOf(user, 1));
    }
}

/**
 * @notice Withdraw contract balance
 * Usage: forge script script/Interactions.s.sol:Withdraw --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast -vvvv
 * Required .env: CONTRACT_ADDRESS
 */
contract Withdraw is Script {
    function run() external {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        uint256 contractBalance = bookTokens.getBalance();
        
        console.log("Withdrawing funds...");
        console.log("Contract:", contractAddress);
        console.log("Owner:", deployer);
        console.log("Contract balance:", contractBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        bookTokens.withdraw();
        
        vm.stopBroadcast();
        
        console.log("Withdrawal successful!");
        console.log("New contract balance:", bookTokens.getBalance());
    }
}

/**
 * @notice View contract information
 * Usage: forge script script/Interactions.s.sol:ViewInfo --rpc-url $BASE_SEPOLIA_RPC_URL -vvvv
 * Required .env: CONTRACT_ADDRESS
 */
contract ViewInfo is Script {
    function run() external view {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        
        console.log("=== FMAOBookTokens Info ===");
        console.log("Contract Address:", contractAddress);
        console.log("Owner:", bookTokens.owner());
        console.log("Book Price:", bookTokens.BOOK_PRICE());
        console.log("Total Books Created:", bookTokens.bookCount());
        console.log("Contract Balance:", bookTokens.getBalance());
        console.log("");
        
        // Show info for each created book
        uint256 totalBooks = bookTokens.bookCount();
        for (uint256 i = 0; i < totalBooks; i++) {
            console.log("--- Book", i, "---");
            console.log("Exists:", bookTokens.bookExists(i));
            console.log("Total Minted:", bookTokens.totalMinted(i));
            console.log("Metadata URI:", bookTokens.uri(i));
            console.log("");
        }
    }
}

/**
 * @notice Check user's book token balances
 * Usage: forge script script/Interactions.s.sol:CheckBalance --rpc-url $BASE_SEPOLIA_RPC_URL -vvvv
 * Required .env: CONTRACT_ADDRESS, USER_ADDRESS
 */
contract CheckBalance is Script {
    function run() external view {
        address payable contractAddress = payable(vm.envAddress("CONTRACT_ADDRESS"));
        address userAddress = vm.envAddress("USER_ADDRESS");
        
        FMAOBookTokens bookTokens = FMAOBookTokens(contractAddress);
        uint256 totalBooks = bookTokens.bookCount();
        
        console.log("=== User Book Balances ===");
        console.log("User:", userAddress);
        console.log("Contract:", contractAddress);
        console.log("");
        
        for (uint256 i = 0; i < totalBooks; i++) {
            uint256 balance = bookTokens.balanceOf(userAddress, i);
            bool hasBook = bookTokens.hasBook(userAddress, i);
            console.log("Book", i);
            console.log("Balance:", balance);
            console.log("Owns:", hasBook);
        }
    }
}