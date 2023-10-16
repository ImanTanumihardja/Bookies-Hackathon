
pragma solidity ^0.8.16;

import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";

contract DataAsserter {
    // Create an Optimistic Oracle V3 instance at the deployed address on Görli.
    OptimisticOracleV3Interface oov3 =
        OptimisticOracleV3Interface(0x263351499f82C107e540B01F0Ca959843e22464a);

    // Asserted claim. This is some truth statement about the world and can be verified by the network of disputers.
    bytes public assertedClaim =
        (abi.encodePacked("Argentina won the 2022 Fifa world cup in Qatar."));

    // Each assertion has an associated assertionID that uniquly identifies the assertion. We will store this here.
    bytes32 public assertionId;

    // Assert the truth against the Optimistic Asserter. This uses the assertion with defaults method which defaults
    // all values, such as a) challenge window to 120 seconds (2 mins), b) identifier to ASSERT_TRUTH, c) bond currency
    //  to USDC and c) and default bond size to 0 (which means we dont need to worry about approvals in this example).
    function assertTruth() public {
        assertionId = oov3.assertTruthWithDefaults(assertedClaim, address(this));
    }

}