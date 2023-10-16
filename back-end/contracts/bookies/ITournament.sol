// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

struct Game {
    string homeTeam;
    string awayTeam;
    string winner;
    bytes32 assertionId;
}

struct Round {
    uint256 roundNumber;
    Game[] games;
    bool isAsserted;
    bool isSettled;
}

struct TournamentInfo {
    string name;
    uint256 startDate;
    uint256 endDate;
    bool hasStarted;
    bool hasEnded;
    bool hasSettled;
    bool isCanceled;
    uint256[] result; // List of number of games each team won
    string[] teamNames; // Adjacent teams are paired together for a game
    uint256 numRounds;
    uint256 upkeepId;
    address  owner;
    address factory;
    address registryAddress;
    address oracleAddress;
}

interface ITournament {

    function getTournamentInfo() view external returns(TournamentInfo memory);

    function getTournamentResult() view external returns(uint256[] memory);

    function cancelTournament() external;

    function withdrawUpkeepFunds() external;
}