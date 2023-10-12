// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import"./ITournament.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./BookiesLibrary.sol";

contract Tournament is ITournament, ChainlinkClient, KeeperCompatibleInterface 
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

    using Chainlink for Chainlink.Request;
    using BookiesLibrary for string;

    /*  Public Variables    */
    uint public counter; // Testing

    /*  Private Variables    */
    string private name;
    uint256 private startDate;
    uint256 private endDate;
    bool private hasStarted;
    bool private hasEnded;
    bool private isCanceled;
    uint private updateInterval; // Use an updateInterval in seconds and a timestamp to slow execution of Upkeep
    uint256 private payment;
    uint256[] private result;
    uint256 private sportsId;
    bytes32 private jobId;
    mapping(uint256 => bytes32[]) private gamesOnDay;
    uint256[] private gameDays;
    mapping(bytes32 => Game) private games;
    uint256 private gameCount;
    string[] private teamNames;
    uint256 private teamCount;
    uint256[] private updateDays;
    mapping(bytes32 => bool) private validGameIds;
    mapping(string => bool) private validTeams;
    bool private isInitialized;
    uint private lastTimeStamp;
    IRegistry private registry;
    uint256 private upkeepId;
    address private owner;
    address private factory;

    uint256 private constant SECONDS_IN_HOUR = 86400;
    uint8 private constant UPDATED_RESULT_STATUS_ID = 101;

    struct GameCreate 
    {
        bytes32 gameId;
        uint256 startTime;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve 
    {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
    }

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
        updateInterval = tournamentInfo.updateInterval;
        gameDays = tournamentInfo.gameDays;
        teamCount = tournamentInfo.teamCount;
        gameCount = tournamentInfo.gameCount;
        updateDays = tournamentInfo.gameDays;
        startDate = tournamentInfo.startDate;
        endDate = tournamentInfo.endDate;
        owner = tournamentInfo.owner;
        factory = tournamentInfo.factory;
        sportsId = tournamentInfo.sportsId;

        setChainlinkToken(linkAddress);
        setChainlinkOracle(oracle);
        jobId = jobId_;
        payment = payment_;
        registry = IRegistry(tournamentInfo.registry);
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

        if (hasStarted && !hasEnded && (time - lastTimeStamp) > updateInterval) {
            upkeepNeeded = true;

            // Gets schedule till game day and gets result after game day
            // for (uint i = 0; i < updateDays.length; i++) {
            //     if (time <= updateDays[i]) {
            //         upkeepNeeded = true;
            //         break;
            //     } 
            //     else if (time > updateDays[i]) {
            //         upkeepNeeded = true;
            //         break;
            //     }
            // }
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
            for (uint i = 0; i < updateDays.length; i++) {
                // Get team names
                requestGamesCreate(updateDays[i], new string[](0), new string[](0));
            }
        }

        (uint time, bool hasStarted_, bool hasEnded_) = abi.decode(performData, (uint, bool, bool));

        if (hasEnded_) {
            hasEnded = true;
        }

        if (hasStarted_) {
            hasStarted = true;
        }

        // Check if should do a market create (get info about games)
        if (hasStarted && !hasEnded && (time - lastTimeStamp) > updateInterval) {
            // Gets schedule till game ends and gets result after game day
            for (uint i = 0; i < updateDays.length; i++) {
                // Get schedule for day
                requestGamesCreate(updateDays[i], new string[](0), new string[](0));

                if (time > updateDays[i]) {
                    // Update result
                    requestGamesResolve(updateDays[i], new string[](0), new string[](0));
                }

                // Gets schedule till game day and gets result after game day
                // if (time <= updateDays[i]) {
                //     // Get schedule for day
                //     this.requestGamesCreate(updateDays[i], new string[](0), new string[](0));
                // } 
                // else if (time > updateDays[i]) {
                //     // Update result
                //     this.requestGamesResolve(time, new string[](0), new string[](0));
                // }
            }
            lastTimeStamp = time;
        }
        // Testing
        if ((time - lastTimeStamp) > updateInterval) {
            lastTimeStamp = time;
            counter = counter + 1;
        }
    }
    
    function fulfillResolve(bytes32 _requestId, bytes[] memory _games) public recordChainlinkFulfillment(_requestId) {
        if (_games.length > 0) {
            GameResolve memory gameResolve = abi.decode(_games[0], (GameResolve));
            Game storage game = games[gameResolve.gameId];
            uint256 gameDay = game.startTime - (game.startTime % SECONDS_IN_HOUR);
            uint256 finishedCount = 0;

            for (uint i = 0; i < _games.length; i++) {
                gameResolve = abi.decode(_games[i], (GameResolve));
                game = games[gameResolve.gameId];

                if (validGameIds[gameResolve.gameId]) {
                    if (game.statusId != UPDATED_RESULT_STATUS_ID) {
                        // Update game information
                        game.statusId = gameResolve.statusId;
                        game.homeScore = gameResolve.homeScore;
                        game.awayScore = gameResolve.awayScore;
                    }

                    if ((game.statusId == 8 || game.statusId == 9 || game.statusId == 11 || game.statusId == 3 || game.statusId == 23)) {
                        finishedCount++;
                        game.statusId = UPDATED_RESULT_STATUS_ID;

                        uint256 idx;
                        // Set the winner team in the result
                        if (gameResolve.homeScore > gameResolve.awayScore) {
                            idx = findTeamIndex(game.homeTeam);
                        } 
                        else if (gameResolve.homeScore < gameResolve.awayScore) {
                            idx = findTeamIndex(game.awayTeam);
                        }
                        else {
                            // TODO: What to do when game ends in tie?
                        }
                        result[idx] += 1;
                    }
                }
            }

            if (finishedCount >= gamesOnDay[gameDay].length) {
                // Remove update day if all games are finished on that day
                for (uint i = 0; i < updateDays.length; i++) {
                    if (updateDays[i] == gameDay) {
                        updateDays[i] = updateDays[updateDays.length - 1];
                        updateDays.pop();
                    }
                }
            }
        }
    }

    function fulfillCreate(bytes32 _requestId, bytes[] memory _games) public recordChainlinkFulfillment(_requestId) {  
        if (_games.length > 0) {
            GameCreate memory gameCreate = abi.decode(_games[0], (GameCreate));
            Game storage game = games[gameCreate.gameId];
            uint256 gameDay = gameCreate.startTime - (gameCreate.startTime % SECONDS_IN_HOUR);

            for (uint i = 0; i < _games.length; i++) {
                gameCreate = abi.decode(_games[i], (GameCreate));
                game = games[gameCreate.gameId];

                if (!validGameIds[gameCreate.gameId]) {
                    // Add to bracketIndexes with next avaliable index
                    validGameIds[gameCreate.gameId] = true;
                    gamesOnDay[gameDay].push(gameCreate.gameId);

                    // Check for new teams
                    if (!validTeams[gameCreate.homeTeam]) {
                        validTeams[gameCreate.homeTeam] = true;
                        result.push();
                        teamNames.push(gameCreate.homeTeam);
                    }
                    if (!validTeams[gameCreate.awayTeam]) {
                        validTeams[gameCreate.awayTeam] = true;
                        result.push();
                        teamNames.push(gameCreate.awayTeam);
                    }
                }

                // Update game information
                game.startTime = gameCreate.startTime;
                game.homeTeam = gameCreate.homeTeam;
                game.awayTeam = gameCreate.awayTeam;
            }
            if (result.length == teamCount && upkeepId != 0) {
                isInitialized = true;
            }
        }
    }

    /**
     * @notice Returns games for a given date.
     * @dev Result format is array of encoded tuples.
     * @param _date the date for the games to be queried (format in epoch).
     * @param _gameIds the IDs of the games to query (array of gameId).
     * @param _statusIds the IDs of the statuses to query (array of statusId).
     */
    function requestGamesResolve(
        uint256 _date,
        string[] memory _statusIds,
        string[] memory _gameIds
    ) internal {
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfillResolve.selector);
        req.addUint("date", _date);
        req.add("market", 'resolve');
        req.addUint("sportId", sportsId);
        req.addStringArray("statusIds", _statusIds);
        req.addStringArray("gameIds", _gameIds);
        sendOperatorRequest(req, payment);
    }

    /**
     * @notice Returns games for a given date.
     * @dev Result format is array of encoded tuples.
     * @param _date the date for the games to be queried (format in epoch).
     * @param _gameIds the IDs of the games to query (array of gameId).
     * @param _statusIds the IDs of the statuses to query (array of statusId).
     */
    function requestGamesCreate(
        uint256 _date,
        string[] memory _statusIds,
        string[] memory _gameIds
    ) internal {
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfillCreate.selector);
        req.addUint("date", _date);
        req.add("market", 'create');
        req.addUint("sportId", sportsId);
        req.addStringArray("statusIds", _statusIds);
        req.addStringArray("gameIds", _gameIds);
        sendOperatorRequest(req, payment);
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