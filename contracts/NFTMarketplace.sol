//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable owner;
    uint256 listPrice = 0.01 ether;

     constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    mapping(uint256 => TokenListed) private idToTokenListed;

    struct TokenListed {
        uint256 tId;
        address payable owner;
        uint256 price;
        bool isCurrentlyListed;
        address payable seller;
    
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }


    function getListingPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToTokenListed() public view returns (TokenListed memory) {
        uint256 currentTId = _tokenIds.current();
        return idToTokenListed[currentTId];
    }

     function getTokenListedForId(uint256 tId) public view returns (TokenListed memory) {
        return idToTokenListed[tId];
    }

    function updateListingPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function tokenCreation(string memory tokenURI, uint256 price) public payable returns (uint) {

        require(msg.value == listPrice, "Send enough ether to list");
        require(price>0, "Make sure the price isn't negative");

        
        _tokenIds.increment();
        uint256 newTId = _tokenIds.current();

        
        _safeMint(msg.sender, newTId);

       
        _setTokenURI(newTId, tokenURI);

        createListedToken(newTId, price);

        return newTId;
    }
    
    function createListedToken(uint256 tId, uint256 priceSent) private {
       
        idToTokenListed[tId] = TokenListed(
            tId,
            payable(address(this)),
            priceSent,
            true,
            payable(msg.sender)
        );
    }

    _transfer(msg.sender, address(this), tId);

    function getAllNFTs() public view returns (TokenListed[] memory) {
        uint nftCount = _tokenIds.current();
        TokenListed[] memory tokensArray = new TokenListed[](nftCount);
        uint cIndex = 0;
        uint ctId;
        
        for(uint i=0;i<nftCount;i++)
        {
            cId = i + 1;
            TokenListed storage cItem = idToTokenListed[cId];
            tokensArray[cIndex] = cItem;
            cIndex += 1;
        }
        return tokensArray;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint cIndex = 0;
        uint cId;
        
        for(uint i=0; i < totItemCount; i++)
        {
            if(idToTokenListed[i+1].owner == msg.sender || idToTokenListed[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }


        TokenListed[] memory items = new TokenListed[](itemCount);
        for(uint i=0; i < totItemCount; i++) {
            if(idToTokenListed[i+1].owner == msg.sender || idToTokenListed[i+1].seller == msg.sender) {
                cId = i+1;
                TokenListed storage cItem = idToTokenListed[cId];
                items[cIndex] = cItem;
                cIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tId) public payable {
        uint sentPrice = idToTokenListed[tId].price;
        address seller = idToTokenListed[tId].seller;
        require(msg.value == sentPrice, "Please submit the asking price in order to complete the purchase");

        
        idToTokenListed[tId].isCurrentlyListed = true;
        idToTokenListed[tId].seller = payable(msg.sender);
        _itemsSold.increment();

       
        _transfer(address(this), msg.sender, tId);
        
        approve(address(this), tId);

       
        payable(owner).transfer(listPrice);
        
        payable(seller).transfer(msg.value);
    }

}