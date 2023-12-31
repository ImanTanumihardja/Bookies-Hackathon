// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ITournament.sol";
import "./KnockoutTournament.sol";
import "./BookiesLibrary.sol";
import "./RequestFactory.sol";

contract TournamentFactory {
    event NewTournament(address);

    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)"));
    uint8 private constant SOURCE = 110;
    LinkTokenInterface public immutable i_link;
    RequestFactory public immutable requestFactory;
    address[] tournaments;

    constructor (address _linkAddress, address _requestFactoryAddress) {
        i_link = LinkTokenInterface(_linkAddress);
        requestFactory = RequestFactory(_requestFactoryAddress);
    }

    function createTournament(uint256 eventID, string calldata name, string[] calldata teamNames, uint256 numRounds, uint256 startDate, uint256[] calldata gameDates) external
    {
        TournamentInfo memory tournamentInfo = TournamentInfo(eventID, name, startDate, false, false, new uint256[](teamNames.length), teamNames, gameDates, numRounds, teamNames.length-1, 0, msg.sender, address(this), address(requestFactory)); 
        KnockoutTournament tournament = new KnockoutTournament(tournamentInfo);

        tournaments.push(address(tournament));
        emit NewTournament(address(tournament));
    }

    function getTournaments() external view returns(address[] memory)
    {
        return tournaments;
    }
}