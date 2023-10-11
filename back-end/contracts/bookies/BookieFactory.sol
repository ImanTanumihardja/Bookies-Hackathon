// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./IBookie.sol";
import "./Bookie.sol";
import "./BookiesLibrary.sol";

contract BookieFactory {

    // IRegistry private registry; // 0x9806cf6fBc89aBF286e8140C42174B94836e36F2; //Goerli testnet 
    // address public erc677LinkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //Goerli testnet (LINK addresses: https://docs.chain.link/docs/link-token-contracts/)

    event NewBookie(address);

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
    address[] bookies;

    constructor (address _linkAddress, address _registrarAddress) {
        i_link = LinkTokenInterface(_linkAddress);
        registrar = KeeperRegistrarInterface(_registrarAddress);
        (, , , address registryAddress, ) = registrar.getRegistrationConfig();
        i_registry = IRegistry(registryAddress);
    }

    function createBookie(string memory name, uint256 buyInPrice, ITournament tournament, uint256 gasLimit) external
    {
        TournamentInfo memory tournamentInfo = tournament.getTournamentInfo();  
        (uint registryFundingAmount, ) = BookiesLibrary.calculateLinkPayment(tournamentInfo.endDate - tournamentInfo.startDate, tournamentInfo.updateInterval, 0, 0, i_registry.getMaxPaymentForGas(gasLimit));

        require(i_link.transferFrom(msg.sender, address(this), registryFundingAmount), "Usage: Could not transfer link");

        BookieInfo memory bookieInfo = BookieInfo(name, msg.sender, 0, buyInPrice, false, false, false, address(tournament), address(i_registry), new address[](0), new address[](0), address(this), false, 0);
        Bookie bookie = new Bookie(bookieInfo);

        // Setup chainlink upkeep

        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;

        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, name, hex"", address(bookie), gasLimit, msg.sender, hex"", registryFundingAmount, SOURCE, address(this)); // CHANGE ADMIN ADDRESS TO TOURNAMNET ADDRESS FOR PRODUCTION
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
            bookie.setUpkeepId(upkeepId);
        } else {
            revert("auto-approve disabled");
        }


        bookies.push(address(bookie));
        emit NewBookie(address(bookie));
    }

    function getBookies() external view returns(address[] memory)
    {
        return bookies;
    }
}