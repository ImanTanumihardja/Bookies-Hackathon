// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import {State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
     function getRegistrationConfig() external view returns (uint autoApproveConfigType, uint32 autoApproveMaxAllowed, uint32 approvedCount, address keeperRegistry, uint256 minLINKJuels);
}

interface IRegistry {
    function withdrawFunds(uint256 id, address to) external;
    function cancelUpkeep(uint256 id) external;
    function getMaxPaymentForGas(uint256 gasLimit) external view returns (uint96 maxPayment);
    function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);
    function getUpkeep(uint256 id) external view returns (address target, uint32 executeGas, bytes memory checkData, uint96 balance,address lastKeeper,address admin,uint64 maxValidBlocknumber,uint96 amountSpent);
    function getState() external view returns (State memory, Config memory, address[] memory);
}

library BookiesLibrary {
    function compareStrings(string memory a, string memory b) pure public returns (bool) 
    {         
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function calculateLinkPayment(uint256 timespan, uint256 updateInterval, uint numGameDays, uint256 apiRequestFee, uint256 maxGasPayment) public pure returns(uint registryFundingAmount, uint totalAPIRequestFee) {
        uint256 MIN_REGISTRY_FUNDING_AMOUNT = 5000000000000000000; // 5 link
        uint8  NUM_REQUEST_PER_UPKEEP = 2;
        
        uint256 numUpdates = timespan <= updateInterval ? 2 : timespan / updateInterval + 1; // you need minimum 2 updates for start: one for initialization and and the other for start and end

        totalAPIRequestFee = ((numUpdates * NUM_REQUEST_PER_UPKEEP * numGameDays) + numGameDays) * apiRequestFee; // for each update you have to make two api request for create and resolve for each game day and for intialization you have to get a create for every gameday

        registryFundingAmount = numUpdates * maxGasPayment;
        registryFundingAmount = registryFundingAmount <= MIN_REGISTRY_FUNDING_AMOUNT ? MIN_REGISTRY_FUNDING_AMOUNT : registryFundingAmount;

        // return (registryFundingAmount, totalAPIRequestFee); // USE FOR PRODUCTION
        return (MIN_REGISTRY_FUNDING_AMOUNT*3, totalAPIRequestFee); // USE FOR TESTING
    }

    function calculateScore(uint256[] memory bracket, uint256[] memory result) public pure returns(uint256 score)
    {
        for (uint i = 0; i < result.length; i++) {
            score += bracket[i] <= result[i] ? bracket[i] : result[i];
        }
        return score;
    }
}
