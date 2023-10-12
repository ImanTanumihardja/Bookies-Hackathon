// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

struct TournamentInfo {
    string name;
    address owner;
    uint256 startDate;
    uint256 endDate;
    bool hasStarted;
    bool hasEnded;
    bool isCanceled;
    uint updateInterval;
    uint lastTimeStamp;
    string[] teamNames;
    uint256 teamCount;
    uint256[] gameDays;
    uint256 gameCount;
    uint256[] result;
    uint sportsId;
    address registry;
    address factory;
    bool isInitialized;
    uint256 upkeepId;
}

interface ITournament {

    function getTournamentInfo() view external returns(TournamentInfo memory tournamentInfo);

    function getTournamentResult() view external returns(uint256[] memory);

    function cancelTournament() external;

    function withdrawLink() external;

    function withdrawUpkeepFunds() external;
}