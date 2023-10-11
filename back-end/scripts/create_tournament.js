/* global ethers */
/* eslint prefer-const: "off" */
var fs = require('fs');
const { mumbai: _MumbaiContractAddresses, goerli: _GoerliContractAddresses} = require("../ContractAddresses.json" )
const { tournamentFactoryAddress: _mumbaiTournamentFactoryAddress, bookiesLibraryAddress: _mumbaiBookiesLibraryAddress } = _MumbaiContractAddresses
const { tournamentFactoryAddress: _goerliTournamentFactoryAddress, bookiesLibraryAddress: _goerliBookiesLibraryAddress } = _GoerliContractAddresses
const _chainlinkTokenABI = require("../abi/LinkTokenInterface.json")
const _chainlinkRegistryABI = require("../abi/IRegistry.json")
const _chainlinkRegistrarABI = require("../abi/KeeperRegistrarInterface.json")

const _erc677LinkAddress_goerli = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const _registrarAddress_goerli = "0x9806cf6fBc89aBF286e8140C42174B94836e36F2";

const _erc677LinkAddress_mumbai = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const _registrarAddress_mumbai = "0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d";


async function createTournament (isTest=false, tournamentFactoryAddress="", bookiesLibraryAddress="") {
  const { TournamentInfo } = require("./tournamentInfoTest")
  var registrarAddress, erc677LinkAddress, tournamentFactoryAddress, bookiesLibraryAddress;
  var tournamentFactoryString = "TournamentFactory";

  if (network.name == "mumbai") {
    erc677LinkAddress = _erc677LinkAddress_mumbai;
    registrarAddress = _registrarAddress_mumbai;
    tournamentFactoryAddress = tournamentFactoryAddress || _mumbaiTournamentFactoryAddress
    bookiesLibraryAddress = bookiesLibraryAddress || _mumbaiBookiesLibraryAddress
  }
  else {
    erc677LinkAddress = _erc677LinkAddress_goerli;
    registrarAddress = _registrarAddress_goerli
    tournamentFactoryAddress = tournamentFactoryAddress || _goerliTournamentFactoryAddress
    bookiesLibraryAddress = bookiesLibraryAddress || _goerliBookiesLibraryAddress
  }

  if (isTest) {
    tournamentFactoryString = "TestTournamentFactory"
  }

  // Create tournament
  console.log('Create Tournament')

  const tournamentFactory = await ethers.getContractAt(tournamentFactoryString, tournamentFactoryAddress)

  // Get max gas payment
  bookiesLibrary = await ethers.getContractAt('BookiesLibrary', bookiesLibraryAddress)
  const chainlinkToken = await ethers.getContractAt(abi=_chainlinkTokenABI, address=erc677LinkAddress)
  const registrar = await ethers.getContractAt(abi=_chainlinkRegistrarABI, address=registrarAddress)
  const [, , , registryAddress, ] = await registrar.getRegistrationConfig()
  const registry = await ethers.getContractAt(abi=_chainlinkRegistryABI, address=registryAddress)
  const maxPaymentForGas = await registry.getMaxPaymentForGas(TournamentInfo.gasLimit)

  // Approve link transfer
  const [registryFundingAmount, totalAPIRequestFee] = await bookiesLibrary.calculateLinkPayment(TournamentInfo.endDate - TournamentInfo.startDate, TournamentInfo.updateInterval, 0, 0, maxPaymentForGas)
  await (await chainlinkToken.approve(tournamentFactory.address, registryFundingAmount.add(totalAPIRequestFee))).wait()
  console.log("Total Chainlink Approval: " + registryFundingAmount.add(totalAPIRequestFee))

  const createTournamentTransaction = await tournamentFactory.createTournament(TournamentInfo.name, TournamentInfo.updateInterval, TournamentInfo.gameDays, TournamentInfo.gameCount, TournamentInfo.teamCount, TournamentInfo.startDate, TournamentInfo.endDate, TournamentInfo.oracle, TournamentInfo.jobId, TournamentInfo.sportsId, TournamentInfo.apiRequestFee, TournamentInfo.gasLimit)
  await createTournamentTransaction.wait();

  const tournaments = await tournamentFactory.getTournaments();
  const tournament = await ethers.getContractAt('Tournament', tournaments[tournaments.length - 1])
  var tournamentInfo = await tournament.getTournamentInfo()

  // Wait for tournament to initialize
  while (!tournamentInfo.isInitialized) {
    await sleep(50000);
    tournamentInfo = await tournament.getTournamentInfo()
  }

  console.log("Tournament Initialized")
  console.log("Created Tournament: " + (await tournament.getTournamentInfo()))
  return tournament.address
}

if (require.main === module) {
  createTournament().then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })

}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = createTournament