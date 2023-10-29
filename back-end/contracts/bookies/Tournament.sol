// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import"./ITournament.sol";
import './RequestFactory.sol';
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./BookiesLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uma/core/contracts/optimistic-oracle-v2/interfaces/OptimisticOracleV2Interface.sol";

contract Tournament is ITournament 
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

    using BookiesLibrary for string;

    /*  Public Variables    */


    /*  Private Variables    */
    IRegistry private registry_;
    uint private lastAssertTime_; // Time of last assertion
    Round[] private rounds; // List of rounds in tournament
    mapping(bytes32 => GameRequestInfo) private gameIndexes_; // Mapping of requestId to game
    TournamentInfo private tournamentInfo_;
    RequestFactory private requestFactory_;

    constructor(TournamentInfo memory tournamentInfo)
    {
        require(!tournamentInfo.name.compareStrings(""), "Usage: Cannot not have empty string as name");
        require(tournamentInfo.startDate > block.timestamp, "Usage: Start date has already passed");

        tournamentInfo_ = tournamentInfo;

        registry_ = IRegistry(tournamentInfo_.registryAddress);
        requestFactory_ = RequestFactory(tournamentInfo_.requestFactoryAddress);

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
                        bytes memory ancillaryData = (abi.encodePacked('q: title: Who won between ', game.homeTeam, ' vs ', game.awayTeam, ' in the ', tournamentInfo_.name, '?, description: This market will resolve to the winner between ', game.homeTeam, ' and ', game.awayTeam, ' in the ', tournamentInfo_.name,'. Please do not propose results before the event ends.', game.homeTeam, ':1 ', game.awayTeam, ':0, unresolvable:0.5'));
                        bytes32 requestID = requestFactory_.requestData(tournamentInfo_.eventId, ancillaryData);
                        game.requestId = requestID;
                        gameIndexes_[requestID] = GameRequestInfo(i, j/2);

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
    function requestSettled(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 price
    ) external {
        require(msg.sender == address(requestFactory_), "not authorized");

        bytes32 requestId = keccak256(abi.encodePacked(identifier, timestamp, ancillaryData));

        uint256 roundNumber = gameIndexes_[requestId].roundNumber;
        uint256 gameIndex = gameIndexes_[requestId].gameIndex;

        Round storage round = rounds[roundNumber];
        Game storage game = round.games[gameIndex];

        require(game.requestId != 0, "Usage: AssertionID does not exist");

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
            bytes memory newAncillaryData = (abi.encodePacked('q: title: Who won between ', game.homeTeam, ' vs ', game.awayTeam, ' in the ', tournamentInfo_.name, '?, description: This market will resolve to the winner between ', game.homeTeam, ' and ', game.awayTeam, ' in the ', tournamentInfo_.name,'. Please do not propose results before the event ends.', game.homeTeam, ':1 ', game.awayTeam, ':0, unresolvable:0.5'));
            bytes32 newAssertionId = requestFactory_.requestData(tournamentInfo_.eventId, newAncillaryData);
            game.requestId = newAssertionId;
            gameIndexes_[newAssertionId] = gameIndexes_[requestId];
            return;
        }

        tournamentInfo_.result[BookiesLibrary.getIndexOfString(tournamentInfo_.teamNames, game.winner)] += 1;

        // Setup next rond
        if (roundNumber < tournamentInfo_.numRounds - 1) {
            Game storage nextRoundGame = rounds[roundNumber+1].games[gameIndex/2];
            if (nextRoundGame.requestId == 0) {
                if (gameIndex % 2 == 0) {
                    nextRoundGame.homeTeam = game.winner;
                }
                else {
                    nextRoundGame.awayTeam = game.winner;
                }

                // Check if ready to assert next game
                if (!nextRoundGame.homeTeam.compareStrings("") && !nextRoundGame.awayTeam.compareStrings("") && nextRoundGame.requestId == 0){
                    // Submit a new request to the Optimistic Oracle
                     bytes memory newAncillaryData = (abi.encodePacked('q:title:Who won between ', nextRoundGame.homeTeam, ' vs ', nextRoundGame.awayTeam, ' in the ', tournamentInfo_.name, '?, description: This market will reslove to the winner between ', nextRoundGame.homeTeam, ' and ', nextRoundGame.awayTeam, ' in the ', tournamentInfo_.name,'. Please do not propose results before the event ends.', nextRoundGame.homeTeam, ':1 ', nextRoundGame.awayTeam, ':0, unresolvable:0.5' ));
                    bytes32 nextRequestID = requestFactory_.requestData(tournamentInfo_.eventId, newAncillaryData);
                    nextRoundGame.requestId = nextRequestID;
                    gameIndexes_[nextRequestID] = GameRequestInfo(roundNumber+1, gameIndex/2);
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
        require(!tournamentInfo_.hasSettled, "Usage: Tournament has already been settled");
        require(tournamentInfo_.startDate < block.timestamp, "Usage: Tournament has started already");
        require(!tournamentInfo_.isCanceled, "Usage: Already canceled");
        require(tournamentInfo_.upkeepId != 0 , "Usage: No UpkeepID");

        tournamentInfo_.isCanceled = true;
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
        require(tournamentInfo_.upkeepId != 0 && (tournamentInfo_.hasSettled || tournamentInfo_.isCanceled), "Usage: Cannot withdraw upkeep funds");

        registry_.withdrawFunds(tournamentInfo_.upkeepId, tournamentInfo_.owner);
    }
}