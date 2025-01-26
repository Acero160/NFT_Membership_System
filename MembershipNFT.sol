//SPDX-License-Identifier: GPL-3-0

/* 

    *** NFT Membership System with Exclusive Access ***
    Description: Create a membership system where NFT holders have exclusive access to content 
    or benefits (such as access to events, discounts, or even other NFTs).
    - Original Features:
    Membership NFTs can have access levels (e.g., gold, silver, bronze).
    Integrate a "burn" function for NFTs to claim unique benefits.

*/


pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract MembershipNFT is ERC721Enumerable, Ownable {

    //Errors
    error DubaiMembershipInsufficientBalance();
    error DubaiMembershipNonExistentToken();
    error DubaiMembershipNotTheOwner();
    error DubaiMembershipNotAllowed();
    error DubaiMembershipExpired();


    //Events
    event NewMembershipMinted(address indexed to, uint256 tokenID, MembershipLevel level);
    event NewMembershipRenewed(address indexed to, uint256 tokenID, MembershipLevel level, uint256 expiration);
    event MembershipBurned(address indexed owner, uint256 tokenID);

    
    //Variables
    uint256 private _currentTokenId;
    enum MembershipLevel {Bronze, Silver, Gold}

    //Mapping
    mapping(uint256 tokenId => MembershipLevel) public membershipLevels;
    mapping (uint256 token => uint256 expiration) public membershipExpiration;

    //Prices
    uint256 bronzePrice = 0.01 ether;
    uint256 silverPrice = 0.01 ether;
    uint256 goldPrice = 0.01 ether;



    constructor() ERC721("Dubai Mermbership", "DXBM") Ownable (msg.sender) {
        _currentTokenId = 0;

}

    //Functions
    function mintDubaiMembership(MembershipLevel level) external payable {
        uint256 price = getPriceForLevel(level);

        if(msg.value < price) {
            revert DubaiMembershipInsufficientBalance();
        }

    _currentTokenId = _currentTokenId +1;

    _safeMint(msg.sender, _currentTokenId);
    membershipLevels[_currentTokenId] = level;
    membershipExpiration [_currentTokenId] = block.timestamp + 365 days;

    emit NewMembershipMinted(msg.sender, _currentTokenId, level);

    }


    function renewMembership(uint256 tokenID) external payable {
        if (!_exists(tokenID)) {
            revert DubaiMembershipNonExistentToken();
        }

        if(ownerOf(tokenID)!= msg.sender){
            revert DubaiMembershipNotTheOwner();
        }
        MembershipLevel level = membershipLevels [tokenID];
        uint256 price = getPriceForLevel(level);

        if(msg.value < price) {
            revert DubaiMembershipInsufficientBalance();
        }

        uint256 newExpirationData = membershipExpiration[tokenID] + 365 days;
        membershipExpiration[tokenID] = newExpirationData;

        emit NewMembershipRenewed(msg.sender, tokenID, level, newExpirationData);

    }





    function getPriceForLevel(MembershipLevel _level) public view returns(uint256) {
        if (_level == MembershipLevel.Gold) {
            return goldPrice;
        } else if (_level == MembershipLevel.Silver) {
            return silverPrice;
        } else  {
            return bronzePrice;
        }
    }


    function _exists(uint256 _tokenID) internal view returns (bool) {
        return ownerOf(_tokenID) != address(0);
    }

    function checkMembershipLevel(address _user) public view returns (MembershipLevel) {
        uint256 balance = balanceOf(_user);
        
        if(balance==0) {
            revert DubaiMembershipInsufficientBalance();
        }

        MembershipLevel level = MembershipLevel.Bronze;

        for(uint256 i = 0; i<balance-1; i++){
            uint256 tokenID = tokenOfOwnerByIndex(_user, i);
            MembershipLevel currentLevel = membershipLevels[tokenID];

            if(currentLevel > level){
                level = currentLevel;
            }
        }

        return level;

    }


    function burnMembership(uint256 tokenID) external {
        if (!_exists(tokenID)) {
            revert DubaiMembershipNonExistentToken();
        }

        if(ownerOf(tokenID)!= msg.sender){
            revert DubaiMembershipNotTheOwner();
        }


        _burn(tokenID);

        emit MembershipBurned(msg.sender, tokenID);
    }


    function isMembershipActive(address _user) public view returns(bool){
          uint256 balance = balanceOf(_user);
        
        if(balance==0) {
            revert DubaiMembershipInsufficientBalance();
        }

        uint256 tokenID = tokenOfOwnerByIndex(_user, balance-1);

        return membershipExpiration[tokenID]>block.timestamp;
    }

    function exclusiveGold( ) external view {
        if(!isMembershipActive(msg.sender)) {
            revert DubaiMembershipExpired();
        }
        if (checkMembershipLevel(msg.sender)!= MembershipLevel.Gold){
            revert DubaiMembershipNotAllowed();
        }

    }

    function withdraw() external onlyOwner {
        payable (owner()).transfer(address(this).balance);
    }

}
