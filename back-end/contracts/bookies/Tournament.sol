// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import"./ITournament.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./BookiesLibrary.sol";
import "./OptimisticOracleV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uma/core/contracts/common/implementation/ExpandedERC20.sol";
import "@uma/core/contracts/common/implementation/Testable.sol";
import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/oracle/implementation/Constants.sol";

import "@uma/core/contracts/oracle/interfaces/OptimisticOracleV2Interface.sol";
import "@uma/core/contracts/oracle/interfaces/IdentifierWhitelistInterface.sol";

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
    // uint public counter; // Testing
    // uint private updateInterval = 60; // Use an updateInterval in seconds and a timestamp to slow execution of Upkeep
    // uint private lastTimeStamp = 0;

    /*  Private Variables    */
    IRegistry private registry_;
    OptimisticOracleV3Interface private oo_;
    uint private lastAssertTime_; // Time of last assertion
    Round[] private rounds; // List of rounds in tournament
    mapping(bytes32 => Game) private games_; // Mapping of assertionId to game
    TournamentInfo private tournamentInfo_;

    bytes32 public priceIdentifier = "YES_OR_NO_QUERY";
    uint64 private livenessTime = 30;
    uint256 private optimisticOracleProposerBond = 500e18;
    uint256 public proposerReward = 10e18;

    constructor(TournamentInfo memory tournamentInfo)
    {
        require(!tournamentInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        require(tournamentInfo.endDate > tournamentInfo.startDate, "Usage: End date is sooner than start date");
        require(tournamentInfo.endDate > block.timestamp, "Usage: End date has already passed");
        require(tournamentInfo.startDate > block.timestamp, "Usage: Start date has already passed");

        tournamentInfo_ = tournamentInfo;

        registry_ = IRegistry(tournamentInfo_.registryAddress);
        oo_ = OptimisticOracleV3Interface(tournamentInfo_.oracleAddress);

        // assertionLiveness = oo_.defaultLiveness();

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
                        games.push(Game(tournamentInfo_.teamNames[j], tournamentInfo_.teamNames[j+1], "", 0));
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

            // Submit a new request to the Optimistic Oracle

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
        // OptimisticOracleV2Interface optimisticOracle = getOptimisticOracle();
        // require(msg.sender == address(optimisticOracle), "not authorized");

        // require(identifier == priceIdentifier, "same identifier");
        // require(keccak256(ancillaryData) == keccak256(customAncillaryData), "same ancillary data");

        // // We only want to process the price if it is for the current price request.
        // if (timestamp != requestTimestamp) return;

        // // Calculate the value of settlementPrice using either 0, 0.5e18, or 1e18 as the expiryPrice.
        // if (price >= 1e18) {
        //     settlementPrice = 1e18;
        // } else if (price == 5e17) {
        //     settlementPrice = 5e17;
        // } else {
        //     settlementPrice = 0;
        // }
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
        bool assertionSettled = false;

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

        if (hasEnded && (time - lastAssertTime_ >= livenessTime) && !tournamentInfo_.hasSettled) {
            assertionSettled = true;
            upkeepNeeded = true;
        }

        // // Testing
        // if ((time - lastTimeStamp) > updateInterval) {
        //     upkeepNeeded = true;
        // }
        
        performData = abi.encode(time, hasStarted, hasEnded, assertionSettled);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override 
    {
        if (tournamentInfo_.isCanceled) {
            return;
        }

        (uint time, bool hasStarted, bool hasEnded, bool assertionSettled) = abi.decode(performData, (uint, bool, bool, bool));

        if (hasEnded && !tournamentInfo_.hasEnded) {
            tournamentInfo_.hasEnded = true;
            // Assert truths for the first round
            settleTournament();
        }

        if (hasEnded && assertionSettled && !tournamentInfo_.hasSettled) {
            // Settle the current tournament round
            settleTournament();
        }

        if (hasStarted && !tournamentInfo_.hasStarted) {
            tournamentInfo_.hasStarted = true;
        }

        // // Testing
        // if ((time - lastTimeStamp) > updateInterval) {
        //     lastTimeStamp = time;
        //     counter = counter + 1;
        // }
    }

    // Assert the truth against the Optimistic Asserter.
    function settleTournament() internal {
        for (uint i = 0; i < tournamentInfo_.numRounds; i++) {
            Round storage round = rounds[i];
            if (round.isSettled) {
                // Continue to the next round since this one is already settled
                continue;
            }
            else if (round.isAsserted) {
                // Check for settlement
                for (uint j = 0; j < round.games.length; j++) {
                    Game storage game = round.games[j];
                    bool result = oo_.settleAndGetAssertionResult(game.assertionId); // Call Optimistic Oracle to settle and get results
                    game.winner = result ? game.homeTeam : game.awayTeam;
                    tournamentInfo_.result[BookiesLibrary.getIndexOfString(tournamentInfo_.teamNames, game.winner)] += 1;
                }

                // Populate the next round with games
                if (i < tournamentInfo_.numRounds - 1) {
                    for (uint j = 0; j < round.games.length; j++) {
                        Game storage game = round.games[j];
                        if (j % 2 == 0) {
                            rounds[i+1].games[j/2].homeTeam = game.winner;
                        }
                        else {
                            rounds[i+1].games[j/2].awayTeam = game.winner;
                        }
                    }
                }
                else {
                    tournamentInfo_.hasSettled = true;
                }
                rounds[i].isSettled = true;

                continue;
            }
            else {
                // Assert truths for round
                for (uint j = 0; j < round.games.length; j++) {
                    Game storage game = round.games[j];
                    bytes memory assertedClaim = (abi.encodePacked(game.homeTeam, ' beat ', game.awayTeam, ' in the ', tournamentInfo_.name));
                    game.assertionId = oo_.assertTruth(
                                                    assertedClaim,
                                                    address(this), // asserter
                                                    address(0), // callbackRecipient
                                                    address(0), // escalationManager
                                                    livenessTime,
                                                    oo_.defaultCurrency(),
                                                    oo_.getMinimumBond(address(oo_.defaultCurrency())),
                                                    oo_.defaultIdentifier(),
                                                    bytes32(0)
                                                ); // Call Optimistic Oracle to assert claim
                }
                rounds[i].isAsserted = true;
                lastAssertTime_ = block.timestamp;
                break;
            }
        }
    }

    /**
     * @notice Request a price in the optimistic oracle for a given request timestamp and ancillary data combo. Set the bonds
     * accordingly to the deployer's parameters. Will revert if re-requesting for a previously requested combo.
     */
    function requestOracleData(bytes claim) internal {
        requestTimestamp = getCurrentTime(); // Set the request timestamp to the current block timestamp.

        OptimisticOracleV2Interface optimisticOracle = getOptimisticOracle();

        collateralToken.safeApprove(address(optimisticOracle), proposerReward);

        optimisticOracle.requestPrice(
            priceIdentifier,
            requestTimestamp,
            claim,
            tournamentInfo_.collateralToken,
            proposerReward
        );

        // Set the Optimistic oracle liveness for the price request.
        optimisticOracle.setCustomLiveness(
            priceIdentifier,
            requestTimestamp,
            claim,
            livenessTime
        );

        // Set the Optimistic oracle proposer bond for the price request.
        optimisticOracle.setBond(priceIdentifier, requestTimestamp, claim, optimisticOracleProposerBond);

        // Make the request an event-based request.
        optimisticOracle.setEventBased(priceIdentifier, requestTimestamp, claim);

        // Enable the priceDisputed and priceSettled callback
        optimisticOracle.setCallbacks(priceIdentifier, requestTimestamp, claim, false, false, true);

        priceRequested = true;
    }

}