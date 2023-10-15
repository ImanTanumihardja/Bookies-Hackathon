// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import"./ITournament.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BookiesLibrary.sol";

contract TestTournament is ITournament, ChainlinkClient, KeeperCompatibleInterface 
{
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

    using BookiesLibrary for string;

    /*  Public Variables    */
    uint public counter; // Testing
    uint private updateInterval;

    /*  Private Variables    */
    string private name;
    uint256 private startDate;
    uint256 private endDate;
    bool private hasStarted;
    bool private hasEnded;
    bool private isCanceled;
    uint256 private payment;
    uint256[] private result;
    uint256 private sportsId;
    bytes32 private jobId;
    uint256[] private gameDays;
    uint256 private gameCount;
    string[] private teamNames;
    uint256 private teamCount;
    bool private isInitialized;
    uint private lastTimeStamp;
    IRegistry private registry;
    uint256 private upkeepId;
    address private owner;
    address private factory;

    struct Game 
    {
        uint256 startTime;
        string homeTeam;
        string awayTeam;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
    } 

    constructor(TournamentInfo memory tournamentInfo, address linkAddress, address oracle, bytes32 jobId_, uint256 payment_)
    {
        require(!tournamentInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        require(tournamentInfo.endDate > tournamentInfo.startDate, "Usage: End date is sooner than start date");
        require(tournamentInfo.endDate > block.timestamp, "Usage: End date has already passed");
        require(tournamentInfo.startDate > block.timestamp, "Usage: Start date has already passed");
        require(tournamentInfo.updateInterval > 0, "Usage: Update updateInterval not valid");
        for (uint i = 0; i < tournamentInfo.gameDays.length; i++) {
            require(tournamentInfo.gameDays[i] >= tournamentInfo.startDate && tournamentInfo.gameDays[i] < tournamentInfo.endDate, "Usage: Game days is not in between start date and end date");
        }

        name = tournamentInfo.name;
        gameDays = tournamentInfo.gameDays;
        teamCount = tournamentInfo.teamCount;
        gameCount = tournamentInfo.gameCount;
        startDate = tournamentInfo.startDate;
        endDate = tournamentInfo.endDate;
        owner = tournamentInfo.owner;
        factory = tournamentInfo.factory;
        sportsId = tournamentInfo.sportsId;
        updateInterval = tournamentInfo.updateInterval;
        jobId = jobId_;
        payment = payment_;
        registry = IRegistry(tournamentInfo.registry);
        setChainlinkToken(linkAddress);
        setChainlinkOracle(oracle);

        // Initialize
        for (uint i = 1; i <= teamCount; i++) {
            result.push();
            teamNames.push(string.concat("Team ", Strings.toString(i)));
        }      
    }

    function setUpkeepId(uint256 upkeepId_) external onlyFactory {
        require(upkeepId == 0, "Usage: upkeepID already set");
        upkeepId = upkeepId_;
    }

    function findTeamIndex(string memory teamName) internal view returns(uint) {
        for (uint i = 0; i < teamNames.length; i++) {
            if (teamName.compareStrings(teamNames[i])) {
                return i;
            }
        }
        return teamNames.length;
    }

    function cancelTournament() external onlyOwner
    {
        require(!hasEnded, "Usage: Tournament has ended already");
        require(!hasStarted, "Usage: Tournament has not started yet");
        require(!isCanceled, "Usage: Already canceled");
        require(upkeepId != 0 , "Usage: No UpkeepID");

        isCanceled = true;
        hasStarted = true;
        hasEnded = true;

        registry.cancelUpkeep(upkeepId);
    }

    function getTournamentResult() view external override returns(uint256[] memory)
    {
        return result;
    }

    function getTournamentInfo() view external override returns(TournamentInfo memory tournamentInfo) {
        tournamentInfo.name = name;
        tournamentInfo.owner = owner;
        tournamentInfo.startDate = startDate;
        tournamentInfo.endDate = endDate;
        tournamentInfo.hasStarted = hasStarted;
        tournamentInfo.hasEnded = hasEnded;
        tournamentInfo.isCanceled = isCanceled;
        tournamentInfo.updateInterval = updateInterval;
        tournamentInfo.lastTimeStamp = lastTimeStamp;
        tournamentInfo.teamNames = teamNames;
        tournamentInfo.teamCount = teamCount;
        tournamentInfo.gameDays = gameDays;
        tournamentInfo.gameCount = gameCount;
        tournamentInfo.result = result;
        tournamentInfo.sportsId = sportsId;
        tournamentInfo.registry = address(registry);
        tournamentInfo.factory = factory;
        tournamentInfo.isInitialized = isInitialized;
        tournamentInfo.upkeepId = upkeepId;
        return tournamentInfo;
    }

    function withdrawUpkeepFunds() external onlyOwner
    {
        require(upkeepId != 0 && (hasEnded || isCanceled), "Usage: Cannot withdraw upkeep funds");

        registry.withdrawFunds(upkeepId, owner);
    }

    /*   Chainlink  */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) 
    {
        uint time = block.timestamp;
        bool hasStarted_ = hasStarted;
        bool hasEnded_ = hasEnded;

        if (!isInitialized) {
            upkeepNeeded = true;
        }

        if (isCanceled) {
            performData = abi.encode(time, hasStarted_, hasEnded_);
            return (upkeepNeeded, performData);
        }

        if (time >= startDate && !hasStarted && !hasEnded) {
            hasStarted_ = true;
            upkeepNeeded = true;
        }

        if (time >= endDate && hasStarted && !hasEnded) {
            hasEnded_ = true;
            upkeepNeeded = true;
        }
        
        // Testing
        if ((time - lastTimeStamp) > updateInterval) {
            upkeepNeeded = true;
        }
        
        performData = abi.encode(time, hasStarted_, hasEnded_);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        if (isCanceled) {
            return;
        }

        if (!isInitialized) {
            if (upkeepId != 0){
                isInitialized = true;
            }
        }

        (uint time, bool hasStarted_, bool hasEnded_) = abi.decode(performData, (uint, bool, bool));

        if (hasEnded_) {
            hasEnded = true;
            // Produce results
            uint teamIdx = 0;
            uint inc = 2;
            for (uint i = 0; i < gameCount; i++) {
                result[teamIdx]++;
                teamIdx += inc;
                if (teamIdx >= teamCount) {
                    teamIdx = 0;
                    inc *= 2;
                }
            }
        }

        if (hasStarted_) {
            hasStarted = true;
        }

        // Testing
        if ((time - lastTimeStamp) > updateInterval) {
            lastTimeStamp = time;
            counter = counter + 1;
        }
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() external onlyOwner
    {
        require(hasEnded || isCanceled, "Usage: Cannot withdraw link");
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }
}