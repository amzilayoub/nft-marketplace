// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftMarketplace is ReentrancyGuard {
	/***********************
	 * Errors
	 **********************/
	error NftMarketplace__NotValidPrice();
	error NftMarketplace__NotApprovedForMarketPlace();
	error NftMarketplace__UnvalidOwner();
	error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
	error NftMarketplace__CannotBuyYourOwnNFT();
	error NftMarketplace__PriceNotMet();
	error NftMarketplace__NotENoughProceeds();
	error NftMarketplace__TransactionProceedsFailed();

	event ItemBought(
		address indexed buyer,
		address indexed nftAddress,
		uint256 indexed tokenId,
		uint256 price
	);

	event ItemCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);

	event ItemUpdated(
		address indexed owner,
		address indexed nftAddress,
		uint256 indexed tokenId,
		uint256 price
	);
	/***********************
	 * Types
	 **********************/
	struct Listing {
		uint256 price;
		address seller;
	}

	/***********************
	 * Variables
	 **********************/
	mapping(address => mapping(uint256 => Listing)) private s_listing;
	mapping(address => uint256) private s_proceeds;

	/***********************
	 * Events
	 **********************/
	event ItemListed(
		address indexed seller,
		address indexed nftAddress,
		uint256 indexed tokenId,
		uint256 price
	);

	/**
	 * check if the marketplace (this contract) is allowed to list the nft
	 * @param nftAddress nft address
	 * @param tokenId token id of the specific nft
	 */
	modifier getApproval(address nftAddress, uint256 tokenId) {
		IERC721 nft = IERC721(nftAddress);
		if (nft.getApproved(tokenId) != address(this)) {
			revert NftMarketplace__NotApprovedForMarketPlace();
		}
		_;
	}

	/**
	 * check if the sender has the ownership to list the nft
	 * @param nftAddress nft address
	 * @param tokenId token id of the specific nft
	 */
	modifier hasOwnership(address nftAddress, uint256 tokenId) {
		IERC721 nft = IERC721(nftAddress);
		if (nft.ownerOf(tokenId) != msg.sender) {
			revert NftMarketplace__UnvalidOwner();
		}
		_;
	}

	/**
	 * check if the nft already listed in the marketplace
	 * @param nftAddress address of the nft
	 * @param tokenId specific token id
	 */
	modifier alreadyListed(address nftAddress, uint256 tokenId) {
		if (s_listing[nftAddress][tokenId].price > 0)
			revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
		_;
	}

	/**
	 * check if the seller is not the buyer
	 * @param nftAddress nft address
	 * @param tokenId nft token id
	 */
	modifier isListed(address nftAddress, uint256 tokenId) {
		if (s_listing[nftAddress][tokenId].price < 0) {
			revert NftMarketplace__CannotBuyYourOwnNFT();
		}
		_;
	}

	/***********************
	 ** Functions
	 **********************/
	/**
	 * listing the nft on the market, and we do the following checks
	 *  1- First check for the price if greater than 0
	 *  2- then check if this contract is eligible to list the nft
	 *  3- check if the sender is the owner
	 * @param nftAddress address of the nft
	 * @param tokenId token id of the specific nft
	 * @param price listing price
	 */
	function listItem(
		address nftAddress,
		uint256 tokenId,
		uint256 price
	)
		external
		hasOwnership(nftAddress, tokenId)
		getApproval(nftAddress, tokenId)
		alreadyListed(nftAddress, tokenId)
	{
		if (price < 0) {
			revert NftMarketplace__NotValidPrice();
		}
		s_listing[nftAddress][tokenId] = Listing(price, msg.sender);
		emit ItemListed(msg.sender, nftAddress, tokenId, price);
	}

	/**
	 * buy nft
	 * @dev we added the modifier nonReentrant to protect from the re entrency attack
	 *      it is basically a mutex that set a variable to true to lock the function
	 *      then set it back to true when the functions execution is finished
	 *      Other option is to set all out state correctly before calling other contracts
	 *      NOTE: In this case, we are safe with the way we sequenced the code
	 * @param nftAddress nft address
	 * @param tokenId token id
	 */
	function buyItem(
		address nftAddress,
		uint256 tokenId
	) external payable isListed(nftAddress, tokenId) nonReentrant {
		Listing memory listedItem = s_listing[nftAddress][tokenId];
		if (listedItem.price < msg.value) {
			revert NftMarketplace__PriceNotMet();
		}
		delete (s_listing[nftAddress][tokenId]);
		s_proceeds[listedItem.seller] += msg.value;
		/* transfer the ownership */
		IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
		emit ItemBought(msg.sender, nftAddress, tokenId, msg.value);
	}

	/**
	 * cancel listing
	 * @param nftAddress nft address
	 * @param tokenId token Id
	 */
	function cancelListing(
		address nftAddress,
		uint256 tokenId
	) external hasOwnership(nftAddress, tokenId) isListed(nftAddress, tokenId) {
		// first check if listed
		// check if is the owner
		delete (s_listing[nftAddress][tokenId]);
		emit ItemCanceled(msg.sender, nftAddress, tokenId);
	}

	/**
	 * update nft price
	 * @param nftAddress nft address
	 * @param tokenId token id
	 * @param price new price
	 */
	function updateListing(
		address nftAddress,
		uint256 tokenId,
		uint256 price
	) external hasOwnership(nftAddress, tokenId) isListed(nftAddress, tokenId) {
		s_listing[nftAddress][tokenId].price = price;
		emit ItemUpdated(msg.sender, nftAddress, tokenId, price);
	}

	/**
	 * Withraw the total proceeds
	 */
	function withdrawProceeds() external nonReentrant {
		uint256 proceeds = s_proceeds[msg.sender];
		if (proceeds <= 0) {
			revert NftMarketplace__NotENoughProceeds();
		}
		(bool success, ) = payable(msg.sender).call{value: s_proceeds[msg.sender]}("");
		if (!success) {
			revert NftMarketplace__TransactionProceedsFailed();
		}
		delete (s_proceeds[msg.sender]);
	}

	/***********************
	 ** Getters
	 **********************/
	/**
	 * get listing
	 * @param nftAddress nft address
	 * @param tokenId token id
	 */
	function getListing(
		address nftAddress,
		uint256 tokenId
	) external view returns (Listing memory) {
		return s_listing[nftAddress][tokenId];
	}

	/**
	 * get proceeds of the sender
	 */
	function getProceeds() external view returns (uint256) {
		return s_proceeds[msg.sender];
	}
}
