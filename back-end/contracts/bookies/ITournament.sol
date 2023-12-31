// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

struct Game {
    string homeTeam;
    string awayTeam;
    string winner;
    bytes32 requestId;
    uint256 date;
}

struct GameRequestInfo{
    uint256 roundNumber;
    uint256 gameIndex;
}

struct Round {
    uint256 roundNumber;
    Game[] games;
}

struct TournamentInfo {
    uint256 eventId;
    string name;
    uint256 startDate;
    bool hasSettled;
    bool isCanceled;
    uint256[] result; // List of number of games each team won
    string[] teamNames; // Adjacent teams are paired together for a game
    uint256[] gameDates;
    uint256 numRounds;
    uint256 numGames;
    uint256 upkeepId;
    address owner;
    address factory;
    address requestFactoryAddress;
}

interface ITournament {

    function getTournamentInfo() view external returns(TournamentInfo memory);

    function getTournamentResult() view external returns(uint256[] memory);
    
    function getRounds() view external returns(Round[] memory);

    function cancelTournament() external;

    function requestSettled(bytes32 identifier, uint256 timestamp, bytes memory ancillaryData,int256 price) external;
}

