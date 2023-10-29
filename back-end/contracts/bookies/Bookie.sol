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
        require(!bookieInfo_.hasEnded, "Usage: Bookie has ended already");
        require(bookieInfo_.hasStarted, "Usage: Bookie has not closed yet");
    }
    modifier duringTournament() {
        _duringTournament();
        _;
    }

    function _beforeTournament() private view {
        require(!bookieInfo_.hasEnded, "Usage: Bookie has ended already");
        require(!bookieInfo_.hasStarted, "Usage: Bookie is closed");
    }
    modifier beforeTournament() {
        _beforeTournament();
        _;
    }

    function _afterTournament() private view {
        require(bookieInfo_.hasEnded, "Usage: Bookie has not ended");
        require(bookieInfo_.hasStarted, "Usage: Bookie has not yet closed");
    }
    modifier afterTournament() {
        _afterTournament();
        _;
    }

    function _notCanceled() private view {
        require(!bookieInfo_.isCanceled, "Usage: Bookie is canceled");
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

    /*  Private Variables    */
    IRegistry private registry_;
    ITournament private tournament_;
    mapping(address => uint256[]) private brackets;
    BookieInfo private bookieInfo_;

    constructor(BookieInfo memory bookieInfo)
    {
        require(!bookieInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        require(bookieInfo.buyInPrice > 0, "Usage: Buy in price must be greater than 0");
        require(bookieInfo.pool == 0, "Usage: Pool must be 0");
        require(bookieInfo.tournamentAddress != address(0), "Usage: Tournament address cannot be 0x0");

        tournament_ = ITournament(bookieInfo.tournamentAddress);
        TournamentInfo memory tournamentInfo = ITournament(bookieInfo.tournamentAddress).getTournamentInfo();

        require(!tournamentInfo.hasSettled, "Usage: Tournament has settled");
        require(tournamentInfo.startDate < block.timestamp, "Usage: Tournament has started already");
        require(!tournamentInfo.isCanceled, "Usage: Tournament is canceled");

        bookieInfo_ = bookieInfo;

        bookieInfo_.buyInPrice *= 1 wei;
        bookieInfo_.startDate = tournamentInfo.startDate;
        bookieInfo_.teamCount = tournamentInfo.teamNames.length;
        bookieInfo_.gameCount = tournamentInfo.numGames;
        registry_ = IRegistry(bookieInfo_.registryAddress);
    }

    function setUpkeepId(uint256 upkeepId) external onlyFactory {
        require(bookieInfo_.upkeepId == 0, "Usage: upkeepID already set");
        bookieInfo_.upkeepId = upkeepId;
    }

    function collectPayout() external payable afterTournament hasBracket
    {
        bool isWinner = false;
        for (uint i = 0; i < bookieInfo_.internalWinners.length; i++) {
            if(bookieInfo_.internalWinners[i] == msg.sender){
                isWinner = true;
                bookieInfo_.internalWinners[i] = bookieInfo_.internalWinners[bookieInfo_.internalWinners.length - 1];
                bookieInfo_.internalWinners.pop();
                break;
            }
        }
        require(isWinner, "You did not win");

        // Pay max score bracket owners
        (bool sent, ) = payable(msg.sender).call{ value: bookieInfo_.payout }("");
        require(sent, "Failed to send Ether");
        bookieInfo_.pool -= bookieInfo_.payout;
    }

    function cancelBookie() external onlyOwner
    {
        cancelBookieInternal();
    }

    function cancelBookieInternal() internal beforeTournament notCanceled
    {
        require(bookieInfo_.upkeepId != 0 , "Usage: No UpkeepID");

        bookieInfo_.internalWinners = bookieInfo_.bracketOwners;
        bookieInfo_.payout = bookieInfo_.buyInPrice;

        bookieInfo_.hasStarted = true;
        bookieInfo_.hasEnded = true;
        bookieInfo_.isCanceled = true;
    }
    
    function createBracket(uint256[] calldata bracket) external payable beforeTournament 
    {
        require(bracket.length == bookieInfo_.teamCount, "Usage: Not the same team count");

        // Check bracket form
        uint256 bracketGameCount = 0;
        for (uint256 i = 0; i < bracket.length; i++) {
            bracketGameCount += bracket[i];
        }
        require(bracketGameCount == bookieInfo_.gameCount, "Usage: Incorrect bracket form");

        if (brackets[msg.sender].length == 0) {
            require(msg.value == bookieInfo_.buyInPrice, "Usage: Incorrect amount of ether");
            bookieInfo_.pool += bookieInfo_.buyInPrice;
            bookieInfo_.bracketOwners.push(msg.sender);
        }

        brackets[msg.sender] = bracket;
    }

    function cancelBracket() external payable beforeTournament hasBracket
    {
        brackets[msg.sender] = new uint256[](0);
        for (uint i = 0; i < bookieInfo_.bracketOwners.length; i++) {
            if (bookieInfo_.bracketOwners[i] == msg.sender) {
                bookieInfo_.bracketOwners[i] = bookieInfo_.bracketOwners[bookieInfo_.bracketOwners.length - 1];
                bookieInfo_.bracketOwners.pop();
                break;
            }
        }

        (bool sent, ) = payable(msg.sender).call{ value: bookieInfo_.buyInPrice }("");
        require(sent, "Failed to send Ether");
        bookieInfo_.pool -= bookieInfo_.buyInPrice;
    }

    function getBookieInfo() external view returns(BookieInfo memory) 
    {
        return bookieInfo_;
    }

    function getBracket(address addr) external view returns(uint256[] memory)
    {
        return brackets[addr];
    }

    function withdrawUpkeepFunds() external onlyOwner
    {
        require(bookieInfo_.upkeepId != 0 && bookieInfo_.hasEnded, "Usage: Cannot withdraw upkeep funds");

        registry_.withdrawFunds(bookieInfo_.upkeepId, bookieInfo_.owner);
    }

    /*   Chainlink  */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) 
    {
        uint time = block.timestamp;
        address[] memory winners;        
        bool hasStarted = bookieInfo_.hasStarted;
        bool hasEnded = bookieInfo_.hasEnded;
        bool isCanceled = bookieInfo_.isCanceled;

        TournamentInfo memory tournamentInfo = tournament_.getTournamentInfo();

        // Check if tournament canceled
        if (!isCanceled && tournamentInfo.isCanceled) {
            isCanceled = true;
            upkeepNeeded = true;
        } 
        else if (isCanceled) {
            isCanceled = true;
            performData = abi.encode(time, winners, hasStarted, hasEnded, isCanceled);
            return (upkeepNeeded, performData);
        }

        // Check if tournament started
        if (!hasStarted && time >= bookieInfo_.startDate) {
            hasStarted = true;
            upkeepNeeded = true;
        }

        // Check if tournament ended
        if (!hasEnded && tournamentInfo.hasSettled) {
            if (bookieInfo_.bracketOwners.length > 0) {
                uint256 maxScore = 0;
                uint256 count = 0;
                address addr;
                uint256 score;
                uint256[] memory result = tournament_.getTournamentResult();
                uint256[] memory scores = new uint256[](bookieInfo_.bracketOwners.length);

                // Find max score and number of max score brackets
                for (uint i = 0; i < bookieInfo_.bracketOwners.length; i++) {
                    addr = bookieInfo_.bracketOwners[i];
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

                winners = new address[](count);
                uint j = 0;
                // Create winners array
                for (uint i = 0; i < bookieInfo_.bracketOwners.length; i++) {
                    addr = bookieInfo_.bracketOwners[i];
                    score = scores[i];
                    if (maxScore == score) {
                        winners[j] = addr;
                        j++;
                    }
                }
            }

            hasEnded = true;
            upkeepNeeded = true;
        }
        
        performData = abi.encode(winners, hasStarted, hasEnded, isCanceled);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        (address[] memory winners, bool hasStarted, bool hasEnded, bool isCanceled) = abi.decode(performData, (address[], bool, bool, bool));
        
        if (isCanceled && !bookieInfo_.isCanceled) {
            cancelBookieInternal();
        } 
        else if (isCanceled){
            return;
        }

        // Check if tournament ended
        if (hasEnded && !isCanceled) {
            bookieInfo_.internalWinners = winners;
            bookieInfo_.winners = winners;

            // No winners
            if (bookieInfo_.internalWinners.length != 0) {
                bookieInfo_.payout = uint(bookieInfo_.pool) / uint(bookieInfo_.internalWinners.length);
            }
            bookieInfo_.hasEnded = true;
        }

        // Check if tournament started
        if (hasStarted && !isCanceled) {
            bookieInfo_.hasStarted = true;
        }
    }
}