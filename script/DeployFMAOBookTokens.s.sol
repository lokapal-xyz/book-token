// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { FMAOBookTokens } from "../src/FMAOBookTokens.sol";

/**
 * @title DeployFMAOBookTokens
 * @notice Deployment script for FMAOBookTokens contract
 * 
 * Usage:
 * Deploy to Base Sepolia:
 * forge script script/DeployFMAOBookTokens.s.sol:DeployFMAOBookTokens --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify -vvvv
 * 
 * Deploy to Base Mainnet:
 * forge script script/DeployFMAOBookTokens.s.sol:DeployFMAOBookTokens --rpc-url $BASE_MAINNET_RPC_URL --broadcast --verify -vvvv
 */
contract DeployFMAOBookTokens is Script {
    // Default placeholder base URI (update after deployment)
    string constant DEFAULT_BASE_URI = "ipfs://placeholder/";
    
    function run() external returns (FMAOBookTokens) {
        // Get deployer from private key in environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying FMAOBookTokens...");
        console.log("Deployer:", deployer);
        console.log("Base URI:", DEFAULT_BASE_URI);
        console.log("Book Price: 0.002 ETH");

        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contract
        FMAOBookTokens bookTokens = new FMAOBookTokens(
            deployer,
            DEFAULT_BASE_URI
        );
        
        vm.stopBroadcast();
        
        console.log("FMAOBookTokens deployed at:", address(bookTokens));
        console.log("Owner:", bookTokens.owner());
        console.log("");
        console.log("Next steps:");
        console.log("1. Upload 0.json to IPFS");
        console.log("2. Call setBaseURI with new IPFS CID");
        console.log("3. Call createBook(0) to enable Book 0");
        
        return bookTokens;
    }
}

/**
 * @title DeployAndSetup
 * @notice Deploy contract and immediately set real base URI + create first book
 * 
 * Usage:
 * forge script script/DeployFMAOBookTokens.s.sol:DeployAndSetup --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify -vvvv
 * 
 * Before running, set in .env:
 * BASE_URI=ipfs://QmYourActualCID/
 */
contract DeployAndSetup is Script {
    function run() external returns (FMAOBookTokens) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        string memory baseURI = vm.envString("BASE_URI");
        
        console.log("Deploying and setting up FMAOBookTokens...");
        console.log("Deployer:", deployer);
        console.log("Base URI:", baseURI);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy
        FMAOBookTokens bookTokens = new FMAOBookTokens(
            deployer,
            baseURI
        );
        
        // Create Book 0
        bookTokens.createBook(0);
        
        vm.stopBroadcast();
        
        console.log("FMAOBookTokens deployed at:", address(bookTokens));
        console.log("Book 0 created and ready for minting");
        console.log("Metadata URI:", bookTokens.uri(0));
        
        return bookTokens;
    }
}