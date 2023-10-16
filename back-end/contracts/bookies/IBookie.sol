// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

struct BookieInfo 
{
    string name;
    uint256 buyInPrice;
    uint pool;
    bool hasStarted;
    bool hasEnded;
    bool isCanceled;
    address[] bracketOwners;
    address[] winners;
    address[] internalWinners;
    uint256 payout;
    address tournamentAddress;
    uint256 teamCount; // Adjacent teams are paired together for a game
    uint256 gameCount;
    uint256 upkeepId;
    address registryAddress;
    address owner;
    address factory;
}

interface IBookie 
{
    function getBookieInfo() external view returns(BookieInfo memory bookieInfo);

    function collectPayout() external payable;

    function cancelBookie() external;
    
    function createBracket(uint256[] calldata bracket) external payable;

    function cancelBracket() external payable; 

    function getBracket(address addr) external view returns(uint256[] memory);

    function withdrawUpkeepFunds() external;
}