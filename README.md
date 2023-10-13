# Bookies
Bookies is a decentralized, non-custiodal sports betting exchange where users can participant as a bettor or bookmaker. 

## Updates 
- Added integration with Moonbeam
- Added multi-chain compatibility
- Improved frontend UI
- Added Coinbase Wallet

## Setup
- You will need a wallet that has test LINK and ETH. (https://faucets.chain.link/)
- You will also need an Alchemy Key. (https://dashboard.alchemy.com/)
1. Clone repository:
```sh
git https://github.com/ImanTanumihardja/Bookies.git
```
2. Install dependencies:
```sh
cd frontend
npm install

cd ..
cd backend
npm install
```
3. Rename `.env.example` to `.env` in `backend` directory and fill in.
4. Rename `.env.local.example` to `.env.local` in `backend` directory and fill in.

## How to run:
### **Frontend**
Inside `frontend` directory run:
```sh
npm run dev
```
If you open http://localhost:3000/ you should see the website
### **Backend**
Inside `backend` directory run:
```sh
npx hardhat balance-nonce
npx hardhat deploy-test-bookies --network goerli --test
```
this will deploy the contracts. 

Next copy the address in the `ContractAddresses.json` from the `backend` directory to the `ContractAddresses.json` in the `frontend` directory (Make sure to leave the ABIs in the `frontend` `ContractAddresses.json`).

Now the contracts are linked to the frontend and you can interact with them.
