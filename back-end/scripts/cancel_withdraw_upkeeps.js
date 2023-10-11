/* global ethers */
/* eslint prefer-const: "off" */
var fs = require('fs');
const { ethers } = require('hardhat');
const chainlinkRegistrarABI = require("../abi/IRegistry.json")
const chainlinkRegistryABI = require("../abi/IUpkeep.json")
const registrarAddress = "0x9806cf6fBc89aBF286e8140C42174B94836e36F2";

async function cancelUpkeeps () {
  console.log('Canceling Upkeeps')

  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  const registrar = await ethers.getContractAt(abi=chainlinkRegistrarABI, registrarAddress)
  const [, , , registryAddress, ] = await registrar.getRegistrationConfig()

  console.log("Registry Address: " + registryAddress)
  console.log("Account: " + contractOwner)
  const registry = await ethers.getContractAt(abi=chainlinkRegistryABI, registryAddress)

  var maxCount = 500;
  var idx = 0;
  while (true) {
      try  {
        const ids = await registry.getActiveUpkeepIDs(idx, idx + maxCount)
        console.log("Getting next set of ids (" + idx + " - " + (idx + maxCount) + ")...")
        for (i = 0; i < ids.length; i++) {
            [ , , , , , admin, , ] = await registry.getUpkeep(ids[i]);
            console.log(admin)
            if (admin == contractOwner) {
              console.log("Canceled Upkeep: " + ids[i])
              await upkeep.cancelUpkeep(ids[i]);
            }
        }
        idx += 500;
      }
      catch (e) {
          maxCount--;
          console.log("Reached Max ID")
          console.log(e);
      }
  }
}

if (require.main === module) {
  cancelUpkeeps()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.cancelUpkeep = cancelUpkeeps
