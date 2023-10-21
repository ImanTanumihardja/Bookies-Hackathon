// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import"./ITournament.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./BookiesLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uma/core/contracts/optimistic-oracle-v2/interfaces/OptimisticOracleV2Interface.sol";

contract Tournament is ITournament, KeeperCompatibleInterface 
{
    function _onlyOwner() private view {
        require(msg.sender == tournamentInfo_.owner);
    }
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyFactory() private view {
        require(msg.sender == tournamentInfo_.factory);
    }
    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    using Chainlink for Chainlink.Request;
    using BookiesLibrary for string;

    /*  Public Variables    */


    /*  Private Variables    */
    IRegistry private registry_;
    uint private lastAssertTime_; // Time of last assertion
    Round[] private rounds; // List of rounds in tournament
    mapping(bytes32 => GameRequestInfo) private gameIndexes_; // Mapping of assertionId to game
    TournamentInfo private tournamentInfo_;
    OptimisticOracleV2Interface private oo_;
    bytes32 private priceIdentifier = "NUMERICAL";
    uint64 private livenessTime = 10;
    uint256 private proposerReward = 0;

    constructor(TournamentInfo memory tournamentInfo)
    {
        require(!tournamentInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        require(tournamentInfo.endDate > tournamentInfo.startDate, "Usage: End date is sooner than start date");
        require(tournamentInfo.endDate > block.timestamp, "Usage: End date has already passed");
        require(tournamentInfo.startDate > block.timestamp, "Usage: Start date has already passed");

        tournamentInfo_ = tournamentInfo;

        registry_ = IRegistry(tournamentInfo_.registryAddress);
        oo_ = OptimisticOracleV2Interface(tournamentInfo_.oracleAddress);

        // Initialize results
        for (uint i = 0; i < tournamentInfo_.teamNames.length; i++) {
            tournamentInfo_.result[i] = 0;
        }

        rounds = new Round[](tournamentInfo_.numRounds);
        // Create rounds
        uint256 teamCount = tournamentInfo_.teamNames.length;
        for (uint i = 0; i < tournamentInfo_.numRounds; i++) {
            rounds[i].roundNumber = i;
            Game[] storage games = rounds[i].games;
            if (i == 0) {
                for (uint j = 0; j < teamCount; j++) {
                    if (j % 2 == 0) {
                        Game memory game = Game(tournamentInfo_.teamNames[j], tournamentInfo_.teamNames[j+1], "", 0);

                        // Submit a new request to the Optimistic Oracle
                        bytes memory assertedClaim = (abi.encodePacked('q:\"Who won between ', game.homeTeam, ' vs ', game.awayTeam, ' in the ', tournamentInfo_.name, '\", ', game.homeTeam, ':1 ', game.awayTeam, ':0, unresolvable:0.5' ));
                        bytes32 assertionID = requestOracleData(assertedClaim);
                        game.assertionId = assertionID;
                        gameIndexes_[assertionID] = GameRequestInfo(i, j/2);

                        games.push(game);
                    }
                }
            }
            else {
                for (uint j = 0; j < teamCount; j++) {
                    if (j % 2 == 0) {
                        games.push(Game("", "", "", 0));
                    }
                }
            }

            teamCount = teamCount / 2;
        }
    }

    /**
     * @notice Callback function called by the optimistic oracle when a price requested by this contract is settled.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data of the price being requested.
     * @param price price that was resolved by the escalation process.
     */
    function priceSettled(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 price
    ) external {
        require(msg.sender == address(oo_), "not authorized");

        bytes32 assertionId = keccak256(abi.encodePacked(identifier, timestamp, ancillaryData, tournamentInfo_.collateralCurrency, proposerReward, livenessTime));

        uint256 roundNumber = gameIndexes_[assertionId].roundNumber;
        uint256 gameIndex = gameIndexes_[assertionId].gameIndex;

        Round storage round = rounds[roundNumber];
        Game storage game = round.games[gameIndex];

        require(game.assertionId != 0, "Usage: AssertionID does not exist");

        if (price >= 1e18) {
            game.winner = game.homeTeam;
        } 
        else if (price == 0) {
            game.winner = game.awayTeam;
        } 
        else{
            // Unresolvable assert again
            game.winner = 'unresolvable';

            // Submit a request to the Optimistic Oracle again
            bytes memory assertedClaim = (abi.encodePacked('q:\"Who won between ', game.homeTeam, ' vs ', game.awayTeam, ' in the ', tournamentInfo_.name, '\", ', game.homeTeam, ':1 ', game.awayTeam, ':0, unresolvable:0.5' ));
            bytes32 newAssertionId = requestOracleData(assertedClaim);
            game.assertionId = newAssertionId;
            gameIndexes_[newAssertionId] = gameIndexes_[assertionId];
            return;
        }

        tournamentInfo_.result[BookiesLibrary.getIndexOfString(tournamentInfo_.teamNames, game.winner)] += 1;

        // Setup next rond
        if (roundNumber < tournamentInfo_.numRounds - 1) {
            Game storage nextRoundGame = rounds[roundNumber+1].games[gameIndex/2];
            if (nextRoundGame.assertionId == 0) {
                if (gameIndex % 2 == 0) {
                    nextRoundGame.homeTeam = game.winner;
                }
                else {
                    nextRoundGame.awayTeam = game.winner;
                }

                // Check if ready to assert next game
                if (!nextRoundGame.homeTeam.compareStrings("") && !nextRoundGame.awayTeam.compareStrings("") && nextRoundGame.assertionId == 0){
                    // Submit a new request to the Optimistic Oracle
                    bytes memory assertedClaim = (abi.encodePacked('q:\"Who won between ', nextRoundGame.homeTeam, ' vs ', nextRoundGame.awayTeam, ' in the ', tournamentInfo_.name, '\", ', nextRoundGame.homeTeam, ':1 ', nextRoundGame.awayTeam, ':0, tie:0.5, unresolvable:-1' ));
                    bytes32 nextAssertionID = requestOracleData(assertedClaim);
                    nextRoundGame.assertionId = nextAssertionID;
                    gameIndexes_[nextAssertionID] = GameRequestInfo(roundNumber+1, gameIndex/2);
                }
            }   
        }
        else { // No more round tournament has settled
            tournamentInfo_.hasSettled = true;
        }
    }

    function getRounds() view external returns(Round[] memory) {
        return rounds;
    }

    function setUpkeepId(uint256 upkeepId) external onlyFactory {
        require(tournamentInfo_.upkeepId == 0, "Usage: upkeepID already set");
        tournamentInfo_.upkeepId = upkeepId;
    }

    function cancelTournament() external onlyOwner
    {
        require(!tournamentInfo_.hasEnded, "Usage: Tournament has ended already");
        require(!tournamentInfo_.hasStarted, "Usage: Tournament has not started yet");
        require(!tournamentInfo_.isCanceled, "Usage: Already canceled");
        require(tournamentInfo_.upkeepId != 0 , "Usage: No UpkeepID");

        tournamentInfo_.isCanceled = true;
        tournamentInfo_.hasStarted = true;
        tournamentInfo_.hasEnded = true;

        registry_.cancelUpkeep(tournamentInfo_.upkeepId);
    }

    function getTournamentResult() view external override returns(uint256[] memory)
    {
        return tournamentInfo_.result;
    }

    function getTournamentInfo() view external override returns(TournamentInfo memory) {
        return tournamentInfo_;
    }

    function withdrawUpkeepFunds() external onlyOwner
    {
        require(tournamentInfo_.upkeepId != 0 && (tournamentInfo_.hasEnded || tournamentInfo_.isCanceled), "Usage: Cannot withdraw upkeep funds");

        registry_.withdrawFunds(tournamentInfo_.upkeepId, tournamentInfo_.owner);
    }

    /*   Chainlink  */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) 
    {
        uint time = block.timestamp;
        bool hasStarted = tournamentInfo_.hasStarted;
        bool hasEnded = tournamentInfo_.hasEnded;

        if (tournamentInfo_.isCanceled) {
            performData = abi.encode(time, hasStarted, hasEnded);
            return (upkeepNeeded, performData);
        }

        if (time >= tournamentInfo_.startDate && !hasStarted && !hasEnded) {
            hasStarted = true;
            upkeepNeeded = true;
        }

        if (time >= tournamentInfo_.endDate && hasStarted && !hasEnded) {
            hasEnded = true;
            upkeepNeeded = true;
        }
        
        performData = abi.encode(hasStarted, hasEnded);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        if (tournamentInfo_.isCanceled) {
            return;
        }

        (bool hasStarted, bool hasEnded) = abi.decode(performData, (bool, bool));

        if (hasEnded && !tournamentInfo_.hasEnded) {
            tournamentInfo_.hasEnded = true;
        }

        if (hasStarted && !tournamentInfo_.hasStarted) {
            tournamentInfo_.hasStarted = true;
        }
    }

    /**
     * @notice Request a price in the optimistic oracle for a given request timestamp and ancillary data combo. Set the bonds
     * accordingly to the deployer's parameters. Will revert if re-requesting for a previously requested combo.
     */
    function requestOracleData(bytes memory assertedClaim) internal returns (bytes32) {
        uint256 requestTimestamp = block.timestamp; // Set the request timestamp to the current block timestamp.

        IERC20(tournamentInfo_.collateralCurrency).approve(address(oo_), proposerReward);

        oo_.requestPrice(
            priceIdentifier,
            requestTimestamp,
            assertedClaim,
            IERC20(tournamentInfo_.collateralCurrency),
            proposerReward
        );

        // Set the Optimistic oracle liveness for the price request.
        uint256 customLiveness = tournamentInfo_.endDate - requestTimestamp > 0 ? tournamentInfo_.endDate - requestTimestamp + livenessTime : livenessTime;
        oo_.setCustomLiveness(
            priceIdentifier,
            requestTimestamp,
            assertedClaim,
            customLiveness
        );

        // Set the Optimistic oracle proposer bond for the price request.
        oo_.setBond(priceIdentifier, requestTimestamp, assertedClaim, tournamentInfo_.proposerBond);

        // Make the request an event-based request.
        oo_.setEventBased(priceIdentifier, requestTimestamp, assertedClaim);

        // Enable the priceSettled callback
        oo_.setCallbacks(priceIdentifier, requestTimestamp, assertedClaim, false, false, true);

        return keccak256(abi.encodePacked(priceIdentifier, requestTimestamp, assertedClaim, tournamentInfo_.collateralCurrency, proposerReward, livenessTime));
    }

}