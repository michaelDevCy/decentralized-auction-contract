// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedAuction {
    address public owner;
    uint public auctionCounter;

    struct Auction {
        uint auctionID;
        address payable seller;
        string itemDescription;
        uint highestBid;
        address payable highestBidder;
        uint auctionEndTime;
        bool auctionEnded;
    }

    mapping(uint => Auction) public auctions;
    mapping(uint => mapping(address => uint)) public pendingReturns;

    event AuctionCreated(uint auctionID, string itemDescription, uint auctionEndTime);
    event NewBid(uint auctionID, address bidder, uint bidAmount);
    event AuctionEnded(uint auctionID, address winner, uint highestBid);

    constructor() {
        owner = msg.sender;
        auctionCounter = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the contract owner.");
        _;
    }

    modifier onlySeller(uint _auctionID) {
        require(msg.sender == auctions[_auctionID].seller, "You are not the seller for this auction.");
        _;
    }

    function createAuction(string memory _itemDescription, uint _startingBid, uint _durationInMinutes) public {
        auctionCounter++;
        uint auctionEndTime = block.timestamp + (_durationInMinutes * 1 minutes);
        auctions[auctionCounter] = Auction({
            auctionID: auctionCounter,
            seller: payable(msg.sender),
            itemDescription: _itemDescription,
            highestBid: _startingBid,
            highestBidder: payable(address(0)),
            auctionEndTime: auctionEndTime,
            auctionEnded: false
        });
        emit AuctionCreated(auctionCounter, _itemDescription, auctionEndTime);
    }

    function placeBid(uint _auctionID) public payable {
        Auction storage auction = auctions[_auctionID];
        require(block.timestamp < auction.auctionEndTime, "Auction has already ended.");
        require(msg.value > auction.highestBid, "There is already a higher or equal bid.");

        if (auction.highestBidder != address(0)) {
            pendingReturns[_auctionID][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);
        emit NewBid(_auctionID, msg.sender, msg.value);
    }

    function withdraw(uint _auctionID) public {
        uint amount = pendingReturns[_auctionID][msg.sender];
        require(amount > 0, "No funds to withdraw.");
        pendingReturns[_auctionID][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction(uint _auctionID) public onlySeller(_auctionID) {
        Auction storage auction = auctions[_auctionID];
        require(block.timestamp >= auction.auctionEndTime, "Auction is still ongoing.");
        require(!auction.auctionEnded, "Auction has already been ended.");

        auction.auctionEnded = true;
        emit AuctionEnded(_auctionID, auction.highestBidder, auction.highestBid);

        uint amount = auction.highestBid;
        auction.highestBid = 0;
        auction.seller.transfer(amount);
    }
}