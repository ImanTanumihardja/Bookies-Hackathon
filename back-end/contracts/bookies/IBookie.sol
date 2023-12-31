// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

struct BookieInfo 
{
    string name;
    bytes32 requestID;
    int256 result;
    uint256 startDate;
    bool hasStarted;
    bool hasSettled;
    bool isCanceled;
    uint256[] odds; // In decimal percent form
    uint256 totalLP;
    uint256 usedLP;
    uint256 upkeepId;
    address[] betters;
    address registryAddress;
    address owner;
    address factory;
    address requestFactoryAddress;
}

    
struct Bet
{
    int256 prediction;
    uint256 wager; 
    uint256 payout;
}

interface IBookie 
{
    function getBookieInfo() external view returns(BookieInfo memory bookieInfo);

    function collectPayout() external payable;

    function cancelBookie() external;
    
    function placeBet(int256 prediction) external payable;

    function cancelBet() external payable; 

    function getBet(address addr) external view returns(Bet memory);

    function withdrawUpkeepFunds() external;
}