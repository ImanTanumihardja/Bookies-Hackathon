// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./ITournament.sol";
import "./TestTournament.sol";
import "./BookiesLibrary.sol";

contract TestTournamentFactory {
    // address internal registry; // = 0x9806cf6fBc89aBF286e8140C42174B94836e36F2; //Goerli testnet 
    // address public erc677LinkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //Goerli testnet (LINK addresses: https://docs.chain.link/docs/link-token-contracts/)

    event NewTournament(address);

    /*
    register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    )
    */

    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)"));
    uint8 private constant SOURCE = 110;
    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable registrar;
    IRegistry public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;
    address[] tournaments;

    constructor (address _linkAddress, address _registrarAddress) {
        i_link = LinkTokenInterface(_linkAddress);
        registrar = KeeperRegistrarInterface(_registrarAddress);
        (, , , address registryAddress, ) = registrar.getRegistrationConfig();
        i_registry = IRegistry(registryAddress);
    }

    function createTournament(string calldata name, uint updateInterval, uint256[] calldata gameDays, uint256 gameCount, uint256 teamCount, uint256 startDate, uint256 endDate, address oracle, bytes32 jobId, uint256 sportsId, uint256 apiRequestFee, uint256 gasLimit) external
    {
        (uint registryFundingAmount, uint totalAPIRequestFee) = BookiesLibrary.calculateLinkPayment(endDate - startDate, updateInterval, 0, 0, i_registry.getMaxPaymentForGas(gasLimit));

        require(i_link.transferFrom(msg.sender, address(this), registryFundingAmount + totalAPIRequestFee), "Usage: Could not transfer link");

        TournamentInfo memory tournamentInfo = TournamentInfo(name, msg.sender, startDate, endDate, false, false, false, updateInterval, 0 , new string[](0), teamCount, gameDays, gameCount, new uint256[](0), sportsId, address(i_registry), address(this), false, 0); 
        TestTournament tournament = new TestTournament(tournamentInfo, address(i_link), oracle, jobId, apiRequestFee);

        // i_link.transfer(address(tournament), totalAPIRequestFee);

        // Setup chainlink upkeep
        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;

        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, name, hex"", address(tournament), gasLimit, msg.sender, hex"", registryFundingAmount, SOURCE, address(this)); // CHANGE ADMIN ADDRESS TO TOURNAMNET ADDRESS FOR PRODUCTION
        i_link.transferAndCall(address(registrar), registryFundingAmount, data);

        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepId = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            tournament.setUpkeepId(upkeepId);
        } else {
            revert("auto-approve disabled");
        }

        tournaments.push(address(tournament));
        emit NewTournament(address(tournament));
    }

    function getTournaments() external view returns(address[] memory)
    {
        return tournaments;
    }
}