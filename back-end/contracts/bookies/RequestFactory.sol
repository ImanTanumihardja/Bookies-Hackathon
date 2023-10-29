// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import"./ITournament.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./BookiesLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uma/core/contracts/optimistic-oracle-v2/interfaces/OptimisticOracleV2Interface.sol";

struct DataRequest{
    uint256 eventID;
    bytes ancillaryData;
    int256 price;
    address callbackAddress;
}

contract RequestFactory
{
    event NewRequest(bytes32);
    using BookiesLibrary for string;

    /*  Public Variables    */
    OptimisticOracleV2Interface public oo;
    uint256 public proposerReward;
    uint256 public proposerBond;
    uint64 public livenessTime;
    address public collateralCurrency;
    bytes32 public priceIdentifier;
    mapping(bytes32 => DataRequest) public dataRequests;
    bytes32[] public requestIDs;

    /*  Private Variables    */


    constructor(address oracleAddress, uint256 _proposerReward, uint256 _proposerBond, uint64 _livenessTime, address _collateralCurrency, bytes32 _priceIdentifier)
    {
        require(oracleAddress != address(0), "Usage: Incorrect Oracle Address");

        // Initialize Optimistic Oracle
        oo = OptimisticOracleV2Interface(oracleAddress);
        proposerReward = _proposerReward;
        livenessTime = _livenessTime;
        collateralCurrency = _collateralCurrency;
        proposerBond = _proposerBond;
        priceIdentifier = _priceIdentifier;
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
        require(msg.sender == address(oo), "not authorized");

        bytes32 requestID = keccak256(abi.encodePacked(identifier, timestamp, ancillaryData));

        DataRequest storage dataRequest = dataRequests[requestID];

        dataRequest.price = price;

        // Call callBack function
        ITournament(dataRequest.callbackAddress).requestSettled(identifier, timestamp, ancillaryData, price);
    }
  

    /**
     * @notice Request a price in the optimistic oracle for a given request timestamp and ancillary data combo. Set the bonds
     * accordingly to the deployer's parameters. Will revert if re-requesting for a previously requested combo.
     */
    function requestData(uint256 eventID, bytes memory ancillaryData) external returns (bytes32 requestID){
        uint256 requestTimestamp = block.timestamp; // Set the request timestamp to the current block timestamp.

        IERC20(collateralCurrency).approve(address(oo), proposerReward);

        oo.requestPrice(
            priceIdentifier,
            requestTimestamp,
            ancillaryData,
            IERC20(collateralCurrency),
            proposerReward
        );

        // Set the Optimistic oracle liveness for the price request.
        oo.setCustomLiveness(
            priceIdentifier,
            requestTimestamp,
            ancillaryData,
            livenessTime
        );

        // Set the Optimistic oracle proposer bond for the price request.
        oo.setBond(priceIdentifier, requestTimestamp, ancillaryData, proposerBond);

        // Make the request an event-based request.
        oo.setEventBased(priceIdentifier, requestTimestamp, ancillaryData);

        // Enable the priceSettled callback
        oo.setCallbacks(priceIdentifier, requestTimestamp, ancillaryData, false, false, true);

        requestID = keccak256(abi.encodePacked(priceIdentifier, requestTimestamp, ancillaryData));
        
        requestIDs.push(requestID);
        dataRequests[requestID] = DataRequest(eventID, ancillaryData, -1, msg.sender);

        emit NewRequest(requestID);

        return requestID;
    }

}