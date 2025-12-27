// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title FMAOBookTokens
 * @notice ERC-1155 token contract for "From Many, as One" book tokens
 * @dev Implements unlimited-supply community support tokens with fixed pricing
 * 
 * Design Philosophy:
 * - One token ID per book (Token 0 = Book 0, Token 1 = Book 1, etc.)
 * - Unlimited supply: anyone can mint anytime
 * - Fixed price per book (0.002 ETH - naturally fluctuates with market)
 * - No artificial scarcity - these are support tokens, not speculative assets
 */
contract FMAOBookTokens is ERC1155, Ownable {
    using Strings for uint256;

    // ============ Errors ============

    error FMAOBookTokens__BookAlreadyExists();
    error FMAOBookTokens__BookDoesNotExist();
    error FMAOBookTokens__BookIdMustBeSequential();
    error FMAOBookTokens__AmountMustBeGreaterThanZero();
    error FMAOBookTokens__InsufficientPayment();
    error FMAOBookTokens__NoFundsToWithdraw();
    error FMAOBookTokens__WithdrawalFailed();
    error FMAOBookTokens__RefundFailed();
    error FMAOBookTokens__InvalidRecipient();
    error FMAOBookTokens__ArrayLengthMismatch();
    error FMAOBookTokens__EmptyArrays();

    // ============ State Variables ============

    /// @notice Base URI for token metadata
    string private _baseMetadataURI;

    /// @notice Fixed price per book token in wei (0.002 ETH)
    uint256 public constant BOOK_PRICE = 0.002 ether;

    /// @notice Tracks total minted for each book token ID
    mapping(uint256 => uint256) public totalMinted;

    /// @notice Tracks which book IDs have been created
    mapping(uint256 => bool) public bookExists;

    /// @notice Counter for total number of books created
    uint256 public bookCount;

    // ============ Events ============

    event BookCreated(uint256 indexed bookId, string metadataURI);
    event BookMinted(address indexed minter, uint256 indexed bookId, uint256 amount);
    event BaseURIUpdated(string newBaseURI);

    // ============ Constructor ============

    /**
     * @param initialOwner Address that will own the contract
     * @param baseURI Base URI for token metadata (e.g., "ipfs://QmHash/")
     */
    constructor(
        address initialOwner,
        string memory baseURI
    ) ERC1155(baseURI) Ownable(initialOwner) {
        _baseMetadataURI = baseURI;
    }

    // ============ Owner Functions ============

    /**
     * @notice Create a new book token
     * @dev Only owner can create new books. BookId auto-increments.
     * @param bookId The ID for the new book (must equal bookCount for sequential ordering)
     */
    function createBook(uint256 bookId) external onlyOwner {
        if (bookExists[bookId]) {
            revert FMAOBookTokens__BookAlreadyExists();
        }
        if (bookId != bookCount) {
            revert FMAOBookTokens__BookIdMustBeSequential();
        }
        
        bookExists[bookId] = true;
        bookCount++;
        
        emit BookCreated(bookId, uri(bookId));
    }

    /**
     * @notice Update the base metadata URI
     * @param newBaseURI New base URI string
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseMetadataURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Withdraw contract balance to owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert FMAOBookTokens__NoFundsToWithdraw();
        }
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) {
            revert FMAOBookTokens__WithdrawalFailed();
        }
    }

    /**
     * @notice Emergency withdraw to specific address
     * @param recipient Address to receive funds
     */
    function withdrawTo(address payable recipient) external onlyOwner {
        if (recipient == address(0)) {
            revert FMAOBookTokens__InvalidRecipient();
        }
        
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert FMAOBookTokens__NoFundsToWithdraw();
        }
        
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) {
            revert FMAOBookTokens__WithdrawalFailed();
        }
    }

    // ============ Public Functions ============

    /**
     * @notice Mint book tokens for a specific book
     * @param bookId The book to mint tokens for
     * @param amount Number of tokens to mint
     */
    function mintBook(uint256 bookId, uint256 amount) external payable {
        if (!bookExists[bookId]) {
            revert FMAOBookTokens__BookDoesNotExist();
        }
        if (amount == 0) {
            revert FMAOBookTokens__AmountMustBeGreaterThanZero();
        }
        
        uint256 totalCost = BOOK_PRICE * amount;
        if (msg.value < totalCost) {
            revert FMAOBookTokens__InsufficientPayment();
        }

        // Mint tokens to sender
        _mint(msg.sender, bookId, amount, "");
        
        // Update total minted
        totalMinted[bookId] += amount;

        emit BookMinted(msg.sender, bookId, amount);

        // Refund excess payment
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            if (!success) {
                revert FMAOBookTokens__RefundFailed();
            }
        }
    }

    /**
     * @notice Mint multiple different books in one transaction
     * @param bookIds Array of book IDs to mint
     * @param amounts Array of amounts for each book ID
     */
    function mintBatch(
        uint256[] memory bookIds,
        uint256[] memory amounts
    ) external payable {
        if (bookIds.length != amounts.length) {
            revert FMAOBookTokens__ArrayLengthMismatch();
        }
        if (bookIds.length == 0) {
            revert FMAOBookTokens__EmptyArrays();
        }

        uint256 totalCost = 0;
        
        // Calculate total cost and validate books exist
        for (uint256 i = 0; i < bookIds.length; i++) {
            if (!bookExists[bookIds[i]]) {
                revert FMAOBookTokens__BookDoesNotExist();
            }
            if (amounts[i] == 0) {
                revert FMAOBookTokens__AmountMustBeGreaterThanZero();
            }
            totalCost += BOOK_PRICE * amounts[i];
        }

        if (msg.value < totalCost) {
            revert FMAOBookTokens__InsufficientPayment();
        }

        // Mint batch
        _mintBatch(msg.sender, bookIds, amounts, "");

        // Update total minted for each book
        for (uint256 i = 0; i < bookIds.length; i++) {
            totalMinted[bookIds[i]] += amounts[i];
            emit BookMinted(msg.sender, bookIds[i], amounts[i]);
        }

        // Refund excess payment
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            if (!success) {
                revert FMAOBookTokens__RefundFailed();
            }
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get the metadata URI for a specific book token
     * @param tokenId The book token ID
     * @return The full metadata URI
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!bookExists[tokenId]) {
            revert FMAOBookTokens__BookDoesNotExist();
        }
        return string(abi.encodePacked(_baseMetadataURI, tokenId.toString(), ".json"));
    }

    /**
     * @notice Get total supply info for a book
     * @param bookId The book token ID
     * @return Total number of tokens minted for this book
     */
    function totalSupply(uint256 bookId) external view returns (uint256) {
        return totalMinted[bookId];
    }

    /**
     * @notice Check if an address owns any tokens for a specific book
     * @param account Address to check
     * @param bookId Book token ID
     * @return True if account owns at least one token
     */
    function hasBook(address account, uint256 bookId) external view returns (bool) {
        return balanceOf(account, bookId) > 0;
    }

    /**
     * @notice Get contract balance
     * @return Current ETH balance of the contract
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get the fixed book price
     * @return Price per book token in wei
     */
    function getBookPrice() external pure returns (uint256) {
        return BOOK_PRICE;
    }

    // ============ Receive Function ============

    /**
     * @notice Allow contract to receive ETH directly
     */
    receive() external payable {}
}