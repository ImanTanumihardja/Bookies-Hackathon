/* global ethers */
/* eslint prefer-const: "off" */
var fs = require('fs');
const {mumbai: _MumbaiContractAddresses, goerli: _GoerliContractAddresses} = require("../ContractAddresses.json")
const { tournamentFactoryAddress: _mumbaiTournamentFactoryAddress, bookieFactoryAddress: _mumbaiBookieFactoryAddress, bookiesLibraryAddress: _mumbaiBookiesLibraryAddress } = _MumbaiContractAddresses
const { tournamentFactoryAddress: _goerliTournamentFactoryAddress, bookieFactoryAddress: _goerliBookieFactoryAddress, bookiesLibraryAddress: _goerliBookiesLibraryAddress } = _GoerliContractAddresses

const _chainlinkTokenABI = require("../abi/LinkTokenInterface.json")
const _chainlinkRegistryABI = require("../abi/IRegistry.json")
const _chainlinkRegistrarABI = require("../abi/KeeperRegistrarInterface.json")

const _erc677LinkAddress_goerli = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const _registrarAddress_goerli = "0x9806cf6fBc89aBF286e8140C42174B94836e36F2";

const _erc677LinkAddress_mumbai = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const _registrarAddress_mumbai = "0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d";


async function getTournamentInfo (tournamentAddress="", tournamentFactoryAddress="") {
  var registrarAddress, erc677LinkAddress, tournamentFactoryAddress, bookieFactoryAddress, bookiesLibraryAddress;

  if (network.name == "mumbai") {
    erc677LinkAddress = _erc677LinkAddress_mumbai;
    registrarAddress = _registrarAddress_mumbai;
    tournamentFactoryAddress = tournamentFactoryAddress || _mumbaiTournamentFactoryAddress
    bookieFactoryAddress = bookieFactoryAddress || _mumbaiBookieFactoryAddress
    bookiesLibraryAddress = bookiesLibraryAddress || _mumbaiBookiesLibraryAddress
  }
  else if (network.name == "goerli") {
    erc677LinkAddress = _erc677LinkAddress_goerli;
    registrarAddress = _registrarAddress_goerli
    tournamentFactoryAddress = tournamentFactoryAddress || _goerliTournamentFactoryAddress
    bookieFactoryAddress = bookieFactoryAddress || _goerliBookieFactoryAddress
    bookiesLibraryAddress = bookiesLibraryAddress || _goerliBookiesLibraryAddress
  }

  console.log("Network: " + network.name)

  // Find tournament address
  let tournament;
  if (!tournamentAddress) {
    const tournamentFactory = await ethers.getContractAt('TournamentFactory', tournamentFactoryAddress)
    const tournamentAddresses = await tournamentFactory.getTournaments();
    for (const ta of tournamentAddresses) {
      tournament = await ethers.getContractAt('Tournament', ta)
    }
  } 
  else {
    tournament = await ethers.getContractAt('Tournament', tournamentAddress)
  }
  console.log(await tournament.getTournamentInfo())
  rounds = await tournament.getRounds()
  for (round of rounds) {
    console.log(round)
    console.log(round[1])
  } 
}

if (require.main === module) {
  getTournamentInfo().then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })

}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = getTournamentInfo
