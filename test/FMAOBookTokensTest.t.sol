// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { FMAOBookTokens } from "../src/FMAOBookTokens.sol";

contract FMAOBookTokensTest is Test {
    FMAOBookTokens public bookTokens;
    
    address public owner;
    address public user1;
    address public user2;
    
    string constant BASE_URI = "ipfs://QmTest/";
    uint256 constant BOOK_PRICE = 0.002 ether;
    
    event BookCreated(uint256 indexed bookId, string metadataURI);
    event BookMinted(address indexed minter, uint256 indexed bookId, uint256 amount);
    event BaseURIUpdated(string newBaseURI);
    
    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy contract as owner
        vm.prank(owner);
        bookTokens = new FMAOBookTokens(owner, BASE_URI);
        
        // Fund test users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    // ============ Deployment Tests ============
    
    function test_Deployment() public view {
        assertEq(bookTokens.owner(), owner);
        assertEq(bookTokens.BOOK_PRICE(), BOOK_PRICE);
        assertEq(bookTokens.bookCount(), 0);
    }
    
    // ============ Book Creation Tests ============
    
    function test_CreateBook() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit BookCreated(0, string(abi.encodePacked(BASE_URI, "0.json")));
        bookTokens.createBook(0);
        
        assertTrue(bookTokens.bookExists(0));
        assertEq(bookTokens.bookCount(), 1);
        assertEq(bookTokens.uri(0), string(abi.encodePacked(BASE_URI, "0.json")));
    }
    
    function test_CreateMultipleBooks() public {
        vm.startPrank(owner);
        
        bookTokens.createBook(0);
        bookTokens.createBook(1);
        bookTokens.createBook(2);
        
        vm.stopPrank();
        
        assertTrue(bookTokens.bookExists(0));
        assertTrue(bookTokens.bookExists(1));
        assertTrue(bookTokens.bookExists(2));
        assertEq(bookTokens.bookCount(), 3);
    }
    
    function test_RevertWhen_NonOwnerCreatesBook() public {
        vm.prank(user1);
        vm.expectRevert();
        bookTokens.createBook(0);
    }
    
    function test_RevertWhen_CreatingDuplicateBook() public {
        vm.startPrank(owner);
        bookTokens.createBook(0);
        
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__BookAlreadyExists.selector);
        bookTokens.createBook(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_CreatingNonSequentialBook() public {
        vm.startPrank(owner);
        
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__BookIdMustBeSequential.selector);
        bookTokens.createBook(1); // Should create 0 first
        
        vm.stopPrank();
    }
    
    // ============ Minting Tests ============
    
    function test_MintBook() public {
        // Create book first
        vm.prank(owner);
        bookTokens.createBook(0);
        
        // Mint as user
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit BookMinted(user1, 0, 1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        
        assertEq(bookTokens.balanceOf(user1, 0), 1);
        assertEq(bookTokens.totalMinted(0), 1);
        assertTrue(bookTokens.hasBook(user1, 0));
    }
    
    function test_MintMultipleBooks() public {
        vm.startPrank(owner);
        bookTokens.createBook(0);
        bookTokens.createBook(1);
        vm.stopPrank();
        
        vm.startPrank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        bookTokens.mintBook{value: BOOK_PRICE * 2}(1, 2);
        vm.stopPrank();
        
        assertEq(bookTokens.balanceOf(user1, 0), 1);
        assertEq(bookTokens.balanceOf(user1, 1), 2);
        assertEq(bookTokens.totalMinted(0), 1);
        assertEq(bookTokens.totalMinted(1), 2);
    }
    
    function test_MintBookWithExcessPayment() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        uint256 userBalanceBefore = user1.balance;
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE + 0.001 ether}(0, 1);
        
        assertEq(bookTokens.balanceOf(user1, 0), 1);
        // Should refund excess
        assertEq(user1.balance, userBalanceBefore - BOOK_PRICE);
    }
    
    function test_RevertWhen_MintingNonexistentBook() public {
        vm.prank(user1);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__BookDoesNotExist.selector);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
    }
    
    function test_RevertWhen_MintingWithInsufficientPayment() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.prank(user1);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__InsufficientPayment.selector);
        bookTokens.mintBook{value: BOOK_PRICE - 1}(0, 1);
    }
    
    function test_RevertWhen_MintingZeroAmount() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.prank(user1);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__AmountMustBeGreaterThanZero.selector);
        bookTokens.mintBook{value: 0}(0, 0);
    }
    
    // ============ Batch Minting Tests ============
    
    function test_MintBatch() public {
        vm.startPrank(owner);
        bookTokens.createBook(0);
        bookTokens.createBook(1);
        vm.stopPrank();
        
        uint256[] memory bookIds = new uint256[](2);
        bookIds[0] = 0;
        bookIds[1] = 1;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;
        
        vm.prank(user1);
        bookTokens.mintBatch{value: BOOK_PRICE * 3}(bookIds, amounts);
        
        assertEq(bookTokens.balanceOf(user1, 0), 1);
        assertEq(bookTokens.balanceOf(user1, 1), 2);
        assertEq(bookTokens.totalMinted(0), 1);
        assertEq(bookTokens.totalMinted(1), 2);
    }
    
    function test_RevertWhen_BatchMintArrayMismatch() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        uint256[] memory bookIds = new uint256[](2);
        bookIds[0] = 0;
        bookIds[1] = 1;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        
        vm.prank(user1);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__ArrayLengthMismatch.selector);
        bookTokens.mintBatch{value: BOOK_PRICE}(bookIds, amounts);
    }
    
    function test_RevertWhen_BatchMintEmptyArrays() public {
        uint256[] memory bookIds = new uint256[](0);
        uint256[] memory amounts = new uint256[](0);
        
        vm.prank(user1);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__EmptyArrays.selector);
        bookTokens.mintBatch{value: 0}(bookIds, amounts);
    }
    
    // ============ URI Tests ============
    
    function test_URI() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        assertEq(bookTokens.uri(0), string(abi.encodePacked(BASE_URI, "0.json")));
    }
    
    function test_SetBaseURI() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        string memory newBaseURI = "ipfs://QmNewHash/";
        
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit BaseURIUpdated(newBaseURI);
        bookTokens.setBaseURI(newBaseURI);
        
        assertEq(bookTokens.uri(0), string(abi.encodePacked(newBaseURI, "0.json")));
    }
    
    function test_RevertWhen_NonOwnerSetsBaseURI() public {
        vm.prank(user1);
        vm.expectRevert();
        bookTokens.setBaseURI("ipfs://QmNewHash/");
    }
    
    function test_RevertWhen_GettingURIForNonexistentBook() public {
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__BookDoesNotExist.selector);
        bookTokens.uri(0);
    }
    
    // ============ Withdrawal Tests ============
    
    function test_Withdraw() public {
        // Create and mint books to accumulate funds
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        
        uint256 contractBalance = address(bookTokens).balance;
        uint256 ownerBalanceBefore = owner.balance;
        
        vm.prank(owner);
        bookTokens.withdraw();
        
        assertEq(address(bookTokens).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }
    
    function test_WithdrawTo() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        
        uint256 contractBalance = address(bookTokens).balance;
        uint256 user2BalanceBefore = user2.balance;
        
        vm.prank(owner);
        bookTokens.withdrawTo(payable(user2));
        
        assertEq(address(bookTokens).balance, 0);
        assertEq(user2.balance, user2BalanceBefore + contractBalance);
    }
    
    function test_RevertWhen_NonOwnerWithdraws() public {
        vm.prank(user1);
        vm.expectRevert();
        bookTokens.withdraw();
    }
    
    function test_RevertWhen_WithdrawingWithNoFunds() public {
        vm.prank(owner);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__NoFundsToWithdraw.selector);
        bookTokens.withdraw();
    }
    
    function test_RevertWhen_WithdrawToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(FMAOBookTokens.FMAOBookTokens__InvalidRecipient.selector);
        bookTokens.withdrawTo(payable(address(0)));
    }
    
    // ============ View Function Tests ============
    
    function test_GetBookPrice() public view {
        assertEq(bookTokens.getBookPrice(), BOOK_PRICE);
    }
    
    function test_GetBalance() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        
        assertEq(bookTokens.getBalance(), BOOK_PRICE);
    }
    
    function test_HasBook() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        assertFalse(bookTokens.hasBook(user1, 0));
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        
        assertTrue(bookTokens.hasBook(user1, 0));
    }
    
    function test_TotalSupply() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        assertEq(bookTokens.totalSupply(0), 0);
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE * 2}(0, 2);
        
        assertEq(bookTokens.totalSupply(0), 2);
        
        vm.prank(user2);
        bookTokens.mintBook{value: BOOK_PRICE * 3}(0, 3);
        
        assertEq(bookTokens.totalSupply(0), 5);
    }
    
    // ============ Edge Case Tests ============
    
    function test_MultipleUsersCanMintSameBook() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.prank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        
        vm.prank(user2);
        bookTokens.mintBook{value: BOOK_PRICE * 2}(0, 2);
        
        assertEq(bookTokens.balanceOf(user1, 0), 1);
        assertEq(bookTokens.balanceOf(user2, 0), 2);
        assertEq(bookTokens.totalMinted(0), 3);
    }
    
    function test_UserCanMintMultipleTimesToIncreaseBalance() public {
        vm.prank(owner);
        bookTokens.createBook(0);
        
        vm.startPrank(user1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        bookTokens.mintBook{value: BOOK_PRICE}(0, 1);
        vm.stopPrank();
        
        assertEq(bookTokens.balanceOf(user1, 0), 3);
        assertEq(bookTokens.totalMinted(0), 3);
    }
    
    function test_ReceiveFunction() public {
        uint256 sendAmount = 1 ether;
        
        (bool success, ) = address(bookTokens).call{value: sendAmount}("");
        assertTrue(success);
        assertEq(address(bookTokens).balance, sendAmount);
    }
    
    // ============ Fuzz Tests ============
    
    function testFuzz_MintBook(uint8 amount) public {
        vm.assume(amount > 0);
        
        vm.prank(owner);
        bookTokens.createBook(0);
        
        uint256 totalCost = BOOK_PRICE * amount;
        vm.deal(user1, totalCost);
        
        vm.prank(user1);
        bookTokens.mintBook{value: totalCost}(0, amount);
        
        assertEq(bookTokens.balanceOf(user1, 0), amount);
        assertEq(bookTokens.totalMinted(0), amount);
    }
    
    function testFuzz_CreateMultipleBooks(uint8 numBooks) public {
        vm.assume(numBooks > 0 && numBooks <= 50); // Reasonable limit
        
        vm.startPrank(owner);
        for (uint256 i = 0; i < numBooks; i++) {
            bookTokens.createBook(i);
        }
        vm.stopPrank();
        
        assertEq(bookTokens.bookCount(), numBooks);
        
        for (uint256 i = 0; i < numBooks; i++) {
            assertTrue(bookTokens.bookExists(i));
        }
    }
}