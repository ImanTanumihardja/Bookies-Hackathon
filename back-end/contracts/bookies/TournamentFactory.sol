// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ITournament.sol";
import "./Tournament.sol";
import "./BookiesLibrary.sol";

contract TournamentFactory {
    event NewTournament(address);

    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)"));
    uint8 private constant SOURCE = 110;
    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable i_registrar;
    IRegistry public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;
    address[] tournaments;

    constructor (address _linkAddress, address _registrarAddress) {
        i_link = LinkTokenInterface(_linkAddress);
        i_registrar = KeeperRegistrarInterface(_registrarAddress);
        (, , , address registryAddress, ) = i_registrar.getRegistrationConfig();
        i_registry = IRegistry(registryAddress);
    }

    function createTournament(string calldata name, string[] calldata teamNames, uint256 numRounds, uint256 startDate, uint256 endDate, address oracleAddress, uint256 gasLimit) external
    {
        uint registryFundingAmount = BookiesLibrary.calculateLinkPayment(i_registry.getMaxPaymentForGas(gasLimit));

        require(i_link.transferFrom(msg.sender, address(this), registryFundingAmount), "Usage: Could not transfer link");

        TournamentInfo memory tournamentInfo = TournamentInfo(name, startDate, endDate, false, false, false, false, new uint256[](teamNames.length), teamNames, numRounds, 0, msg.sender, address(this), address(i_registry), oracleAddress); 
        Tournament tournament = new Tournament(tournamentInfo);

        // Setup chainlink upkeep
        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;

        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, name, hex"", address(tournament), gasLimit, msg.sender, hex"", registryFundingAmount, SOURCE, address(this)); // CHANGE ADMIN ADDRESS TO TOURNAMNET ADDRESS FOR PRODUCTION
        i_link.transferAndCall(address(i_registrar), registryFundingAmount, data);

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