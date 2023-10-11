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


async function createBookie (tournamentAddress="", tournamentFactoryAddress="", bookieFactoryAddress="", bookiesLibraryAddress="") {
  const {BookieInfo} = require("./bookieInfo")
  var registrarAddress, erc677LinkAddress, tournamentFactoryAddress, bookieFactoryAddress, bookiesLibraryAddress;

  if (network.name == "mumbai") {
    erc677LinkAddress = _erc677LinkAddress_mumbai;
    registrarAddress = _registrarAddress_mumbai;
    tournamentFactoryAddress = tournamentFactoryAddress || _mumbaiTournamentFactoryAddress
    bookieFactoryAddress = bookieFactoryAddress || _mumbaiBookieFactoryAddress
    bookiesLibraryAddress = bookiesLibraryAddress || _mumbaiBookiesLibraryAddress
  }
  else {
    erc677LinkAddress = _erc677LinkAddress_goerli;
    registrarAddress = _registrarAddress_goerli
    tournamentFactoryAddress = tournamentFactoryAddress || _goerliTournamentFactoryAddress
    bookieFactoryAddress = bookieFactoryAddress || _goerliBookieFactoryAddress
    bookiesLibraryAddress = bookiesLibraryAddress || _goerliBookiesLibraryAddress
  }

  // Find tournament address
  if (!tournamentAddress) {
    const tournamentFactory = await ethers.getContractAt('TournamentFactory', tournamentFactoryAddress)
    const tournaments = await tournamentFactory.getTournaments();
    tournamentAddress = tournaments[tournaments.length - 1];
  }

  // Create bookie
  console.log('Creating Bookie')

  const bookieFactory = await ethers.getContractAt('BookieFactory', bookieFactoryAddress)

  // Get max gas payment
  bookiesLibrary = await ethers.getContractAt('BookiesLibrary', bookiesLibraryAddress)
  const chainlinkToken = await ethers.getContractAt(abi=_chainlinkTokenABI, address=erc677LinkAddress)
  const registrar = await ethers.getContractAt(abi=_chainlinkRegistrarABI, address=registrarAddress)
  const [, , , registryAddress, ] = await registrar.getRegistrationConfig()
  const registry = await ethers.getContractAt(abi=_chainlinkRegistryABI, address=registryAddress)
  const maxPaymentForGas = await registry.getMaxPaymentForGas(BookieInfo.gasLimit)

  // Get tournament info
  const tournament = await ethers.getContractAt('Tournament', tournamentAddress)
  const tournamentInfo = await tournament.getTournamentInfo()

  // Approve link transfer
  const [bookieRegistryFundingAmount, bookieTotalAPIRequestFee] = await bookiesLibrary.calculateLinkPayment(tournamentInfo.endDate - tournamentInfo.startDate, tournamentInfo.updateInterval, 0, 0, maxPaymentForGas)
  await (await chainlinkToken.approve(bookieFactory.address,  bookieRegistryFundingAmount.add(bookieTotalAPIRequestFee))).wait()
  console.log("Total Chainlink Approval: " + (bookieRegistryFundingAmount.add(bookieTotalAPIRequestFee)))

  const createBookieTransaction = await bookieFactory.createBookie(BookieInfo.name, 1, tournamentAddress, BookieInfo.gasLimit)
  await createBookieTransaction.wait()
  const bookies = await bookieFactory.getBookies();
  const bookie = await ethers.getContractAt('Bookie', bookies[bookies.length - 1])

  var bookieInfo = await bookie.getBookieInfo()

  // Wait for tournament to initialize
  while (!bookieInfo.isInitialized) {
    await sleep(50000);
    bookieInfo = await bookie.getBookieInfo()
  }

  console.log("Bookie Initialized")
  console.log("Created Bookie: " + (await bookie.getBookieInfo()))
  return bookie.address
}


if (require.main === module) {
  createBookie().then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })

}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = createBookie
