// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface OptimisticOracleV3Interface {
    function defaultIdentifier() external view returns (bytes32);

    function defaultCurrency() external view returns (IERC20);

    function defaultLiveness() external view returns (uint64);

    function assertTruthWithDefaults(bytes memory claim, address asserter) external returns (bytes32);

    function assertTruth(
        bytes memory claim,
        address asserter,
        address callbackRecipient,
        address escalationManager,
        uint64 liveness,
        IERC20 currency,
        uint256 bond,
        bytes32 identifier,
        bytes32 domainId
    ) external returns (bytes32);

    function settleAndGetAssertionResult(bytes32 assertionId) external returns (bool);

    function getMinimumBond(address currency) external view returns (uint256);

    function getAssertionResult(bytes32 assertionId) external view returns (bool);
}