/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require('hardhat-abi-exporter')
require('dotenv').config({path:__dirname+'/.env'})
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const { Alchemy, Network, Wallet, Utils } = require("alchemy-sdk");
require('./tasks')

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = process.env.ALCHEMY_KEY;


// Replace this private key with your Goerli account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

task("account", "returns nonce and balance for specified address on multiple networks")
  .addParam("address")
  .setAction(async address => {
    const web3Goerli = createAlchemyWeb3('https://eth-goerli.g.alchemy.com/v2/' + ALCHEMY_API_KEY);
    const web3Sepolia = createAlchemyWeb3('https://eth-sepolia.g.alchemy.com/v2/' + ALCHEMY_API_KEY);
    const web3Mumbai = createAlchemyWeb3('https://polygon-mumbai.g.alchemy.com/v2/' + ALCHEMY_API_KEY);

    const networkIDArr = ["Ethereum Goerli:", "Polygon  Mumbai:"]
    const providerArr = [web3Goerli, web3Mumbai, web3Sepolia];
    const resultArr = [];
    
    for (let i = 0; i < providerArr.length; i++) {
      const nonce = await providerArr[i].eth.getTransactionCount(address.address, "latest");
      const balance = await providerArr[i].eth.getBalance(address.address)
      resultArr.push([networkIDArr[i], nonce, parseFloat(providerArr[i].utils.fromWei(balance, "ether")).toFixed(2) + "ETH"]);
    }
    resultArr.unshift(["  |NETWORK|   |NONCE|   |BALANCE|  "])
    console.log(resultArr);
  });


task("balance-nonce", "makes nonce on different networks equal")
  .setAction(async () => {
    // Creates an Alchemy object instance with the config to use for making requests
    const goerliAlchemy = new Alchemy({ apiKey: ALCHEMY_API_KEY, network: Network.ETH_GOERLI});
    const sepoliaAlchemy = new Alchemy({ apiKey: ALCHEMY_API_KEY, network: Network.ETH_SEPOLIA});
    const mumbaiAlchemy = new Alchemy({ apiKey: ALCHEMY_API_KEY, network: Network.MATIC_MUMBAI});
                                      
    const wallet = new Wallet(PRIVATE_KEY);

    // define the transaction
    const transaction = {
        to: wallet.address,
        value: Utils.parseEther("0.0"),
        gasLimit: "21000",
        maxPriorityFeePerGas: Utils.parseUnits("5", "gwei"),
        maxFeePerGas: Utils.parseUnits("20", "gwei"),
        type: 2,
        chainId: 5, // Corresponds to ETH_GOERLI
      };

    let goerliNonce = await goerliAlchemy.core.getTransactionCount(wallet.getAddress());
    let sepoliaNonce = await sepoliaAlchemy.core.getTransactionCount(wallet.getAddress());
    let mumbaiNonce = await mumbaiAlchemy.core.getTransactionCount(wallet.getAddress());

    console.log('Goerli Nonce: ' + goerliNonce)
    console.log('Mumbai Nonce: ' + mumbaiNonce)
    console.log('Sepolia Nonce: ' + sepoliaNonce)

    while (goerliNonce != mumbaiNonce){
      if (goerliNonce > mumbaiNonce){
        transaction.nonce = mumbaiNonce
        transaction.chainId = 80001
        const rawTransaction = await wallet.signTransaction(transaction);
        const response = await mumbaiAlchemy.transact.sendTransaction(rawTransaction)

        await response.wait()
        
        mumbaiNonce = await mumbaiAlchemy.core.getTransactionCount(wallet.getAddress());

        console.log('Updated Mumbai Nonce: ' + mumbaiNonce)
      }
      else {
        transaction.nonce = goerliNonce
        transaction.chainId = 5
        const rawTransaction = await wallet.signTransaction(transaction);
        const response = await goerliAlchemy.transact.sendTransaction(rawTransaction)

        await response.wait()

        goerliNonce = await goerliAlchemy.core.getTransactionCount(wallet.getAddress());

        console.log('Updated Goerli Nonce: ' + goerliNonce)
      }
    }
  });

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    }
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [PRIVATE_KEY],
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [PRIVATE_KEY]
    }
  },
  abiExporter: {
    path: './abi',
    runOnCompile: true,
    clear: true,
    flat: true,
    only: [],
    except: [':ILinkToken$'],
    spacing: 2,
    format: "json",
  }
}

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task('accounts', 'Prints the list of accounts', async () => {
//   const accounts = await ethers.getSigners()

//   for (const account of accounts) {
//     console.log(account.address)
//   }
// })
