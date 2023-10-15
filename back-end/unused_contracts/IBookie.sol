// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

struct BookieInfo 
{
    string name;
    address owner;
    uint256 pool;
    uint256 buyInPrice;
    bool hasStarted;
    bool hasEnded;
    bool isCanceled;
    address tournament;
    address registry;
    address[] bracketOwners;
    address[] winners;
    address factory;
    bool isInitialized;
    uint256 upkeepId;
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