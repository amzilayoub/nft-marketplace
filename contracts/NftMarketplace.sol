// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftMarketplace {
	/***********************
	 * Errors
	 **********************/
	error NftMarketplace__NotValidPrice();
	error NftMarketplace__NotApprovedForMarketPlace();
	error NftMarketplace__UnvalidOwner();
	error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);

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

	/***********************
	 * Events
	 **********************/
	event ItemListed(
		address indexed seller,
		address indexed nftAddress,
		uint256 indexed tokenId,
		uint256 price
	);

	/************************
	 * Modifiers
	 ***********************/
	/**
	 *  check if price if valid
	 * @param price nft price
	 */
	modifier validPrice(uint256 price) {
		if (price <= 0) {
			revert NftMarketplace__NotValidPrice();
		}
		_;
	}

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
		validPrice(price)
		hasOwnership(nftAddress, tokenId)
		getApproval(nftAddress, tokenId)
		alreadyListed(nftAddress, tokenId)
	{
		s_listing[nftAddress][tokenId] = Listing(price, msg.sender);
		emit ItemListed(msg.sender, nftAddress, tokenId, price);
	}
}
