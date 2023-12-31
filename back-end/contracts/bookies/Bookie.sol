// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./IBookie.sol";
import "./BookiesLibrary.sol";
import './RequestFactory.sol';

contract Bookie is IBookie, KeeperCompatibleInterface 
{
    using BookiesLibrary for string;

    function _onlyOwner() private view {
        require(msg.sender == bookieInfo_.owner);
    }
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyFactory() private view {
        require(msg.sender == bookieInfo_.factory);
    }
    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    function _duringTournament() private view {
        require(!bookieInfo_.hasSettled, "Usage: Bookie has ended already");
        require(bookieInfo_.hasStarted, "Usage: Bookie has not closed yet");
    }
    modifier duringTournament() {
        _duringTournament();
        _;
    }

    function _beforeEvent() private view {
        require(!bookieInfo_.hasSettled, "Usage: Bookie has ended already");
        require(!bookieInfo_.hasStarted, "Usage: Bookie is closed");
    }
    modifier beforeEvent() {
        _beforeEvent();
        _;
    }

    function _afterEvent() private view {
        require(bookieInfo_.hasSettled, "Usage: Bookie has not ended");
        require(bookieInfo_.hasStarted, "Usage: Bookie has not yet closed");
    }
    modifier afterEvent() {
        _afterEvent();
        _;
    }

    function _notCanceled() private view {
        require(!bookieInfo_.isCanceled, "Usage: Bookie is canceled");
    }
    modifier notCanceled() {
        _notCanceled();
        _;
    }

    function _hasBet() private view {
        require(bets_[msg.sender].wager != 0, "Usage: You don't have a bet");
    }
    modifier hasBet() {
        _hasBet();
        _;
    }

     /*  Public variables    */

    /*  Private Variables    */
    IRegistry private registry_;
    BookieInfo private bookieInfo_;
    RequestFactory private requestFactory_;
    mapping(address => Bet) private bets_;

    constructor(BookieInfo memory bookieInfo) payable
    {
        require(!bookieInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        require(bookieInfo.totalLP == msg.value, "Usage: You did not send enough Liqiudity");

        bookieInfo_ = bookieInfo;

        registry_ = IRegistry(bookieInfo_.registryAddress);
        requestFactory_ = RequestFactory(bookieInfo_.requestFactoryAddress);
    }

    function setUpkeepId(uint256 upkeepId) external onlyFactory {
        require(bookieInfo_.upkeepId == 0, "Usage: upkeepID already set");
        bookieInfo_.upkeepId = upkeepId;
    }

    function collectPayout() external payable afterEvent hasBet
    {
        Bet memory bet = bets_[msg.sender];
        require(bet.prediction == bookieInfo_.result, "Usage: You did not win.");

        // Remove better from list
        for (uint i = 0; i < bookieInfo_.betters.length; i++) {
            if (bookieInfo_.betters[i] == msg.sender) {
                bookieInfo_.betters[i] = bookieInfo_.betters[bookieInfo_.betters.length - 1];
                bookieInfo_.betters.pop();
                break;
            }
        }

        (bool sent, ) = payable(msg.sender).call{ value: bet.wager }("");
        require(sent, "Failed to send Ether");
        bookieInfo_.usedLP -= bet.wager;
        bets_[msg.sender] = Bet(0, 0, 0);
    }

    function cancelBookie() external onlyOwner
    {
        cancelBookieInternal();
    }

    function cancelBookieInternal() internal beforeEvent notCanceled
    {
        require(bookieInfo_.upkeepId != 0 , "Usage: No UpkeepID");


        bookieInfo_.hasStarted = true;
        bookieInfo_.hasSettled = true;
        bookieInfo_.isCanceled = true;
    }
    
    function placeBet(int256 prediction) external payable beforeEvent 
    {
        require(msg.value > 0, "Usage: Wager must be greater than 0");
        require(prediction == 1 || prediction == 0, "Usage: Invalid prediction");
        
        // Check if enough LP to place bet with given odds
        uint256 payout = msg.value / bookieInfo_.odds[uint256(prediction)];
        require(bookieInfo_.usedLP + payout <= bookieInfo_.totalLP, "Usage: Wager amount too large");

        bets_[msg.sender] = Bet(prediction, msg.value, payout);
        bookieInfo_.betters.push(msg.sender);
        bookieInfo_.usedLP += payout;
    }

    function cancelBet() external payable beforeEvent hasBet
    {
        for (uint i = 0; i < bookieInfo_.betters.length; i++) {
            if (bookieInfo_.betters[i] == msg.sender) {
                bookieInfo_.betters[i] = bookieInfo_.betters[bookieInfo_.betters.length - 1];
                bookieInfo_.betters.pop();
                break;
            }
        }

        (bool sent, ) = payable(msg.sender).call{ value: bets_[msg.sender].wager }("");
        require(sent, "Failed to send Ether");
        bookieInfo_.usedLP -= bets_[msg.sender].wager;
        bets_[msg.sender] = Bet(0, 0, 0);
    }

    function getBookieInfo() external view returns(BookieInfo memory) 
    {
        return bookieInfo_;
    }

    function getBet(address addr) external view returns(Bet memory)
    {
        return bets_[addr];
    }

    function withdrawUpkeepFunds() external onlyOwner
    {
        require(bookieInfo_.upkeepId != 0 && bookieInfo_.hasSettled, "Usage: Cannot withdraw upkeep funds");

        registry_.withdrawFunds(bookieInfo_.upkeepId, bookieInfo_.owner);
    }

    /*   Chainlink  */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) 
    {
        uint time = block.timestamp;
        int256 result;        
        bool hasStarted = bookieInfo_.hasStarted;
        bool hasSettled = bookieInfo_.hasSettled;
        bool isCanceled = bookieInfo_.isCanceled;

        // Check if tournament canceled
        if (isCanceled) {
            isCanceled = true;
            performData = abi.encode(result, hasStarted, hasSettled, isCanceled);
            return (upkeepNeeded, performData);
        }

        // Check if tournament started
        if (!hasStarted && time >= bookieInfo_.startDate) {
            hasStarted = true;
            upkeepNeeded = true;
        }

        // Check if game has settled from requestFactory TODO
        DataRequest memory dataRequest_ = requestFactory_.getDataRequest(bookieInfo_.requestID);
        if (!hasSettled && dataRequest_.hasSettled) {
            result = dataRequest_.price;

            hasSettled = true;
            upkeepNeeded = true;
        }
        
        performData = abi.encode(result, hasStarted, hasSettled, isCanceled);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        (int256 result, bool hasStarted, bool hasSettled, bool isCanceled) = abi.decode(performData, (int256, bool, bool, bool));
        
        if (isCanceled && !bookieInfo_.isCanceled) {
            cancelBookieInternal();
        } 
        else if (isCanceled){
            return;
        }

        // Check if tournament ended
        if (hasSettled && !bookieInfo_.hasSettled) {
            bookieInfo_.result = result;
            bookieInfo_.hasSettled = true;
        }

        // Check if tournament started
        if (hasStarted && !isCanceled) {
            bookieInfo_.hasStarted = true;
        }
    }
}