/* global ethers */
/* eslint prefer-const: "off" */
var fs = require('fs');
const contractAddresses = require("../ContractAddresses.json")
const create_tournament = require("./create_tournament")
const create_bookie = require("./create_bookie")

const _erc677LinkAddress_goerli = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const erc677LinkAddress_mumbai = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

const _registrarAddress_goerli = "0x9806cf6fBc89aBF286e8140C42174B94836e36F2";
const _registrarAddress_mumbai = "0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d";

var _erc677LinkAddress;
var _registrarAddress;

var _tournamentFactoryString = "TournamentFactory";

async function deployBookies (isTest=false, runChecks=false) {
  const {RequestFactoryInfo} = require("./requestFactoryInfo")

  if (network.name == "mumbai") {
    _erc677LinkAddress = erc677LinkAddress_mumbai;
    _registrarAddress = _registrarAddress_mumbai;
  }
  else {
    _erc677LinkAddress = _erc677LinkAddress_goerli;
    _registrarAddress = _registrarAddress_goerli
  }

  console.log("DEPLOYING CONTRACTS")
  console.log("Network: " + network.name)
  console.log("Is Test: " + isTest + "\n")

  const [account] = await ethers.getSigners()

  // Add link token address
  contractAddresses[network.name]["chainlinkTokenAddress"] = _erc677LinkAddress;

  const BookiesLibrary = await ethers.getContractFactory('BookiesLibrary')
  const bookiesLibrary = await BookiesLibrary.deploy()
  await bookiesLibrary.deployed()
  console.log('BookiesLibrary deployed:', bookiesLibrary.address)
  contractAddresses[network.name]["bookiesLibraryAddress"] = bookiesLibrary.address;

  const RequestFactory = await ethers.getContractFactory('RequestFactory')
  const requestFactory = await RequestFactory.deploy(RequestFactoryInfo.oracleAddress, RequestFactoryInfo.proposerReward, RequestFactoryInfo.proposerBond, RequestFactoryInfo.livenessTime, RequestFactoryInfo.collateralCurrency, ethers.utils.formatBytes32String(RequestFactoryInfo.priceIdentifier))
  await requestFactory.deployed()
  console.log('RequestFactory deployed:', requestFactory.address)
  contractAddresses[network.name]["requestFactoryAddress"] = requestFactory.address;

  // Create tournament factory
  const TournamentFactory = await ethers.getContractFactory(_tournamentFactoryString, {
    signer: account,
    libraries: {
      BookiesLibrary: bookiesLibrary.address,
    },
  })
  
  const tournamentFactory = await TournamentFactory.deploy(_erc677LinkAddress, _registrarAddress, requestFactory.address)
  await tournamentFactory.deployed()
  console.log('TournamentFactory deployed:', tournamentFactory.address)
  contractAddresses[network.name]["tournamentFactoryAddress"] = tournamentFactory.address;

  // // Create bookie factory
  // const BookieFactory = await ethers.getContractFactory('BookieFactory', {
  //   signer: account,
  //   libraries: {
  //     BookiesLibrary: bookiesLibrary.address,
  //   },
  // })
  // const bookieFactory = await BookieFactory.deploy(_erc677LinkAddress, _registrarAddress)
  // await bookieFactory.deployed()
  // console.log('BookieFactory deployed:', bookieFactory.address)
  // contractAddresses[network.name]["bookieFactoryAddress"] = bookieFactory.address;

   // Create contract addresses json
   fs.writeFileSync(`./ContractAddresses.json`, JSON.stringify(contractAddresses), function(err) {
    if (err) {
        console.log(err);
    }
  });

  if (runChecks) {
    // Testing Functions
    console.log("\nTESTING FACTORIES\n")

    // Create tournament
    const tournamentAddress = await create_tournament(isTest, tournamentFactory.address, bookiesLibrary.address)
    console.log("Tournament Address: " + tournamentAddress  + "\n")

    // // Create bookie
    // const bookieAddress = await create_bookie(tournamentAddress, tournamentFactory.address, bookieFactory.address, bookiesLibrary.address)
    // console.log("Bookie Address: " + bookieAddress)
  }
}

if (require.main === module) {
  deployBookies(false, false)
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

module.exports = deployBookies
