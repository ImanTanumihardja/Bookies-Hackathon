// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import "./ITournament.sol";
import "./IBookie.sol";
import "./BookiesLibrary.sol";

contract Bookie is IBookie, KeeperCompatibleInterface 
{
    using BookiesLibrary for string;

    function _onlyOwner() private view {
        require(msg.sender == owner);
    }
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyFactory() private view {
        require(msg.sender == factory);
    }
    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    function _duringTournament() private view {
        require(!hasEnded, "Usage: Bookie has ended already");
        require(hasStarted, "Usage: Bookie has not closed yet");
    }
    modifier duringTournament() {
        _duringTournament();
        _;
    }

    function _beforeTournament() private view {
        require(!hasEnded, "Usage: Bookie has ended already");
        require(!hasStarted, "Usage: Bookie is closed");
    }
    modifier beforeTournament() {
        _beforeTournament();
        _;
    }

    function _afterTournament() private view {
        require(hasEnded, "Usage: Bookie has not ended");
        require(hasStarted, "Usage: Bookie has not yet closed");
    }
    modifier afterTournament() {
        _afterTournament();
        _;
    }

    function _notCanceled() private view {
        require(!isCanceled, "Usage: Bookie is canceled");
    }
    modifier notCanceled() {
        _notCanceled();
        _;
    }

    function _hasBracket() private view {
        require(brackets[msg.sender].length != 0, "Usage: You don't have a bracket");
    }
    modifier hasBracket() {
        _hasBracket();
        _;
    }

     /*  Public variables    */
    uint public counter; // Testing

    /*  Private Variables    */
    string private name;
    uint256 private teamCount;
    uint256 private gameCount;
    uint256 private buyInPrice;
    uint private pool;
    uint256 private closeDate;
    bool private hasStarted;
    bool private hasEnded;
    bool private isCanceled;
    address[] private bracketOwners;
    address[] private winners;
    address[] private internalWinners;
    uint256 private payout;
    ITournament private tournament;
    uint private updateInterval; // Use an updateInterval in seconds and a timestamp to slow execution of Upkeep
    mapping(address => uint256[]) private brackets;
    uint private lastTimeStamp;
    uint256 private upkeepId;
    IRegistry private registry;
    address private owner;
    address private factory;
    bool private isInitialized;

    uint256 private constant UPKEEP_BUFFER = 60; // Seconds

    constructor(BookieInfo memory bookieInfo)
    {
        require(!bookieInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        tournament = ITournament(bookieInfo.tournament);
        TournamentInfo memory tournamentInfo = tournament.getTournamentInfo();

        require(tournamentInfo.isInitialized, "Usage: Tournament is not initialized");
        require(!tournamentInfo.hasEnded, "Usage: Tournament has ended ");
        require(!tournamentInfo.hasStarted, "Usage: Tournament has started already");
        require(!tournamentInfo.isCanceled, "Usage: Tournament is canceled");

        name = bookieInfo.name;
        owner = bookieInfo.owner;
        factory = bookieInfo.factory;
        closeDate = tournamentInfo.startDate - UPKEEP_BUFFER;
        buyInPrice = bookieInfo.buyInPrice * 1 wei;
        teamCount = tournamentInfo.teamCount;
        gameCount = tournamentInfo.gameCount;
        updateInterval = tournamentInfo.updateInterval;
        registry = IRegistry(bookieInfo.registry);
    }

    function setUpkeepId(uint256 upkeepId_) external onlyFactory {
        require(upkeepId == 0, "Usage: upkeepID already set");
        upkeepId = upkeepId_;
    }

    function collectPayout() external payable afterTournament hasBracket
    {
        bool isWinner = false;
        for (uint i = 0; i < internalWinners.length; i++) {
            if(internalWinners[i] == msg.sender){
                isWinner = true;
                internalWinners[i] = internalWinners[internalWinners.length - 1];
                internalWinners.pop();
                break;
            }
        }
        require(isWinner, "You did not win");

        // Pay max score bracket owners
        (bool sent, ) = payable(msg.sender).call{ value: payout }("");
        require(sent, "Failed to send Ether");
        pool -= payout;
    }

    function cancelBookie() external onlyOwner
    {
        cancelBookieInternal();
    }

    function cancelBookieInternal() internal beforeTournament notCanceled
    {
        require(upkeepId != 0 , "Usage: No UpkeepID");

        internalWinners = bracketOwners;
        payout = buyInPrice;

        hasStarted = true;
        hasEnded = true;
        isCanceled = true;
    }
    
    function createBracket(uint256[] calldata bracket) external payable beforeTournament 
    {
        require(bracket.length == teamCount, "Usage: Not the same team count");

        // Check bracket form
        uint256 bracketGameCount = 0;
        for (uint256 i = 0; i < bracket.length; i++) {
            bracketGameCount += bracket[i];
        }
        require(bracketGameCount == gameCount, "Usage: Incorrect bracket form");

        if (brackets[msg.sender].length == 0) {
            require(msg.value == buyInPrice, "Usage: Incorrect amount of ether");
            pool += buyInPrice;
            bracketOwners.push(msg.sender);
        }

        brackets[msg.sender] = bracket;
    }

    function cancelBracket() external payable beforeTournament hasBracket
    {
        brackets[msg.sender] = new uint256[](0);
        for (uint i = 0; i < bracketOwners.length; i++) {
            if (bracketOwners[i] == msg.sender) {
                bracketOwners[i] = bracketOwners[bracketOwners.length - 1];
                bracketOwners.pop();
                break;
            }
        }

        (bool sent, ) = payable(msg.sender).call{ value: buyInPrice }("");
        require(sent, "Failed to send Ether");
        pool -= buyInPrice;
    }

    function getBookieInfo() external view returns(BookieInfo memory bookieInfo) 
    {
        bookieInfo.name = name;
        bookieInfo.owner = owner;
        bookieInfo.pool = pool;
        bookieInfo.buyInPrice = buyInPrice;
        bookieInfo.tournament = address(tournament);
        bookieInfo.hasStarted = hasStarted;
        bookieInfo.hasEnded = hasEnded;
        bookieInfo.isCanceled = isCanceled;
        bookieInfo.bracketOwners = bracketOwners;
        bookieInfo.winners = winners;
        bookieInfo.factory = factory;
        bookieInfo.registry = address(registry);
        bookieInfo.upkeepId = upkeepId;
        bookieInfo.isInitialized = isInitialized;
        return bookieInfo;
    }

    function getBracket(address addr) external view returns(uint256[] memory)
    {
        return brackets[addr];
    }

    function withdrawUpkeepFunds() external onlyOwner
    {
        require(upkeepId != 0 && hasEnded, "Usage: Cannot withdraw upkeep funds");

        registry.withdrawFunds(upkeepId, owner);
    }

    /*   Chainlink  */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) 
    {
        uint time = block.timestamp;
        address[] memory winners_;        
        bool hasStarted_ = false;
        bool hasEnded_ = false;
        bool isCanceled_ = false;

        TournamentInfo memory tournamentInfo = tournament.getTournamentInfo();

        if (!isInitialized) {
            upkeepNeeded = true;
        }

        // Check if tournament canceled
        if (!isCanceled && tournamentInfo.isCanceled) {
            isCanceled_ = true;
            upkeepNeeded = true;
        } 
        else if (isCanceled) {
            isCanceled_ = true;
            performData = abi.encode(time, winners_, hasStarted_, hasEnded_, isCanceled_);
            return (upkeepNeeded, performData);
        }

        // Check if tournament started
        if (!hasStarted && time >= closeDate) {
            hasStarted_ = true;
            upkeepNeeded = true;
        }

        // Check if tournament ended
        if (!hasEnded && tournamentInfo.hasEnded) {
            if (bracketOwners.length > 0) {
                uint256 maxScore = 0;
                uint256 count = 0;
                address addr;
                uint256 score;
                uint256[] memory result = tournament.getTournamentResult();
                uint256[] memory scores = new uint256[](bracketOwners.length);

                // Find max score and number of max score brackets
                for (uint i = 0; i < bracketOwners.length; i++) {
                    addr = bracketOwners[i];
                    score = BookiesLibrary.calculateScore(brackets[addr], result);
                    scores[i] = score;
                    if (maxScore < score) {
                        maxScore = score;
                        count = 1;
                    }
                    else if (maxScore == score) {
                        count++;
                    }
                }

                winners_ = new address[](count);
                uint j = 0;
                // Create winners array
                for (uint i = 0; i < bracketOwners.length; i++) {
                    addr = bracketOwners[i];
                    score = scores[i];
                    if (maxScore == score) {
                        winners_[j] = addr;
                        j++;
                    }
                }
            }

            hasEnded_ = true;
            upkeepNeeded = true;
        }

        // Testing
        if ((time - lastTimeStamp) > updateInterval) { //&& hasStarted && !hasEnded) {
            upkeepNeeded = true;
        }
        
        performData = abi.encode(time, winners_, hasStarted_, hasEnded_, isCanceled_);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        (uint time, address[] memory winners_, bool hasStarted_, bool hasEnded_, bool isCanceled_) = abi.decode(performData, (uint, address[], bool, bool, bool));
        
        if (isCanceled_ && !isCanceled) {
            cancelBookieInternal();
        } 
        else if (isCanceled){
            return;
        }

        if (!isInitialized) {
            if (upkeepId != 0){
                isInitialized = true;
            }
        }

        // Check if tournament ended
        if (hasEnded_ && !isCanceled_) {
            internalWinners = winners_;
            winners = winners_;
            if (internalWinners.length != 0) {
                payout = uint(pool) / uint(internalWinners.length);
            }
            hasEnded = true;
        }

        // Check if tournament started
        if (hasStarted_ && !isCanceled_) {
            hasStarted = true;
        }

        // Testing
        if ((time - lastTimeStamp) > updateInterval) { //&& hasStarted && !hasEnded) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
        }
    }
}