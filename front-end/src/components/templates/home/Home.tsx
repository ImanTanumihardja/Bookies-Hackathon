import {
  VStack,
} from '@chakra-ui/react';
import Link from 'next/link'

const Home = () => {
  const openInNewTab = (url: string) => {
    window.open(url, '_blank', 'noopener,noreferrer');
  };
  return (
    <VStack w={'full'} p="4" rounded="lg" className="space-y-0">
      <div className="flex items-center w-full h-96 overflow-clip">
        <div className="w-2/3">
          <div>
            <h1 className="font-display text-6xl font-bold text-orange-500 mb-4">Bookies: Decentralized, Non-custodial Sports Betting</h1>
            <h2 className="text-2xl ">The first bracket based web3 betting platform</h2>
          </div>
          <br />
          <div className="flex space-x-4">
            <button className="primary-button"><Link href="/bookies">Start Betting</Link></button>
            <button className="secondary-button" 
            onClick = {
              () => openInNewTab('https://docs.google.com/document/d/17iwILCL2sNeXQfO10tXnlaT2QbfpwkstpF_J4pJCrtw/edit?usp=sharing')
              }
            >Learn More</button>
          </div>
        </div>
        <div className="self-start">
          <img className="bg-orange-500 aspect-square rounded-full" src="/home-page.jpeg"></img>
        </div>
      </div>

      <div className="bg-gray-800 w-full rounded-md p-6 grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="flex space-x-4">
          <img src="/abstract-1.webp" className="h-16 w-16 rounded-sm object-cover"></img>
          <div>
            <h1 className="font-bold font-display">Connect your wallet</h1>
            <p className="text-xs opacity-80">Integrated with MetaMask, WalletConnect, etc</p>
          </div>
        </div>
        <div className="flex space-x-4">
          <img src="/abstract-2.webp" className="h-16 w-16 rounded-sm object-cover"></img>
          <div>
            <h1 className="font-bold font-display">Find your tournament</h1>
            <p className="text-xs opacity-80">Wide variety of competitions to select from</p>
          </div>
        </div>
        <div className="flex space-x-4">
          <img src="/abstract-3.webp" className="h-16 w-16 rounded-sm object-cover"></img>
          <div>
            <h1 className="font-bold font-display">Create or find a Bookie</h1>
            <p className="text-xs opacity-80">Customizable bookies allow for a unique betting experience</p>
          </div>
        </div>
        <div className="flex space-x-4">
          <img src="/abstract-4.jpeg" className="h-16 w-16 rounded-sm object-cover"></img>
          <div>
            <h1 className="font-bold font-display">Fill in your bracket and bet</h1>
            <p className="text-xs opacity-80">Enjoy betting with millions of others</p>
          </div>
        </div>
      </div>

      <br />
      <br />

      <div className="bg-gray-800 rounded-md p-6 w-full flex  flex-col md:flex-row overflow-clip gap-8">
        <div className="w-3/5">
          <h3 className="font-mono">Benefits 💪</h3>
          <h1 className="text-5xl font-display font-bold">Power of Bookies.</h1>
        </div>
        <p className=" bg-white/10 rounded-md text-lg opacity-90 p-4 mt-4">
        While the online sports betting industry is growing at a rapid rate, there are glaring flaws that need addressing. 
        Online betting sites like Stake.com, DraftKings, and FanDuel are popular choices among sports enthusiasts and 
        gamblers due to their user-friendly interfaces and wide range of betting options. However, these sites have to act
        as a trusted escrow for funds, ensuring that customer deposits and winnings are held securely and processed. While 
        these sites seem trustworthy, recent examples such as FTX highlight the problem with centralizing your trust in a 
        third party: “not your keys, not your coins”. Additionally, users are at the whim of these online sites when it comes 
        to settlement. These websites retain the authority to make the decision in situations where there is ambiguity 
        regarding the outcome of an event. Users are also constrained by the specific betting odds provided exclusively by 
        these platforms, which are designed to favor the house. There is currently no product on the market that addresses these 
        concerns, which is precisely what Bookies aims to accomplish.
        </p>
      </div>

      <br />
      <br />

      <div className="bg-gray-800 rounded-md p-6 w-full overflow-clip ">
        <div className="w-3/5">
          <h3 className="font-mono">The Future 🚀</h3>
          <h1 className="text-5xl font-display font-bold">Roadmap.</h1>
        </div>
        <br />
        <div className="w-full my-8 grid grid-cols-2 lg:grid-cols-5 gap-8">
          <div className="flex flex-col items-center justify-center space-y-4">
            <div className="h-24 w-24 rounded-full bg-gradient-to-br from-slate-500 to-purple-500"></div>
            <div className="text-center">
              <h3 className="text-xs font-mono">(12/22)</h3>
              <h1 className="font-bold text-xl font-display">Tokenomics</h1>
              <p className="text-xs">Launch of the $BOOK token 📕</p>
            </div>
          </div>
          <div className="flex flex-col items-center justify-center space-y-4">
            <div className="h-24 w-24 rounded-full bg-gradient-to-br from-emerald-500 to-purple-500"></div>
            <div className="text-center">
              <h3 className="text-xs font-mono">(1/23)</h3>
              <h1 className="font-bold text-xl font-display">Pooled Bookie Liquidity </h1>
              <p className="text-xs">Earn even more yields 💰</p>
            </div>
          </div>
          <div className="flex flex-col items-center justify-center space-y-4">
            <div className="h-24 w-24 rounded-full bg-gradient-to-br from-yellow-500 to-purple-500"></div>
            <div className="text-center">
              <h3 className="text-xs font-mono">(2/23)</h3>
              <h1 className="font-bold text-xl font-display">Plug and Play UX</h1>
              <p className="text-xs">Improved betting experience 🎲</p>
            </div>
          </div>
          <div className="flex flex-col items-center justify-center space-y-4">
            <div className="h-24 w-24 rounded-full bg-gradient-to-br from-red-500 to-purple-500"></div>
            <div className="text-center">
              <h3 className="text-xs font-mono">(3/23)</h3>
              <h1 className="font-bold text-xl font-display">DAO</h1>
              <p className="text-xs">Escrowed token for voting 🗳️</p>
            </div>
          </div>
          <div className="flex flex-col items-center justify-center space-y-4">
            <div className="h-24 w-24 rounded-full bg-gradient-to-br from-orange-500 to-purple-500"></div>
            <div className="text-center">
              <h3 className="text-xs font-mono">(4/20)</h3>
              <h1 className="font-bold text-xl font-display">Multichain</h1>
              <p className="text-xs">Launch of other chains 🌎</p>
            </div>
          </div>
        </div>
      </div>

      <br />
      <br />
    </VStack>
  );
};

export default Home;
