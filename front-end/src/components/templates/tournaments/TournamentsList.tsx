import {
  Box,
  Accordion,
  AccordionButton,
  AccordionItem,
  AccordionPanel,
  AccordionIcon,
  Button,
  Spinner,
  Flex,
  Spacer,
  Center,
} from '@chakra-ui/react';
import { BorderContainer } from 'components/elements/containers';
import { readContract } from '@wagmi/core';
import contractInfo from '../../../../ContractAddresses.json';
import { FC, useEffect, useReducer, useState } from 'react';
import { ITournaments } from './types';
import { sportsId } from 'utils/sportsId';

const {
  bookieFactoryABI,
  tournamentABI,
  chainlinkTokenABI,
  bookieABI,
  tournamentFactoryABI,
  chainlinkTokenAddress,
  bookiesLibraryAddress,
  tournamentFactoryAddress,
  bookieFactoryAddress
} = contractInfo;


const TournamentsList: FC<ITournaments> = (props: ITournaments) => {

  const { tournamentFilter } = props;
  
  const [tournamentListState, setTournamentListState] = useReducer(
    (state: any, newState: any) => ({ ...state, ...newState }),
    { tournaments: new Map(), isLoading: false }
  );

  useEffect(() => {
    getTournaments();
  }, []);

  const getTournaments = async () => {
    setTournamentListState({ isLoading: true })

    try {
      const tournamentAddresses = await readContract({
        address: tournamentFactoryAddress,
        abi: tournamentFactoryABI,
        functionName: 'getTournaments',
      });
      console.log(tournamentAddresses);

      // Get tournament info
      var tournaments = new Map();
      for (const address of tournamentAddresses as string[]) {
        const tournamentInfo: any = await readContract({
          address: address,
          abi: tournamentABI,
          functionName: 'getTournamentInfo',
        });
        console.log(tournamentInfo)
        tournaments.set(address, tournamentInfo);
      }
      setTournamentListState({ tournaments });
    } catch (error) {
      console.error(error);
    }
    setTournamentListState({isLoading: false})
  };

  return (
    <>
      <div className="mb-2">
            <BorderContainer>
              <div className="flex justify-between items-center">
                <div>
                  <div className="text-3xl font-bold font-display">Browse Tournaments</div>
                  <div>Look for a tournament and click on it to see its details</div>
                </div>
              </div>
            </BorderContainer>
          </div>
          {(tournamentListState.isLoading ? <Center><Spinner size='xl'/></Center> :
        <Accordion allowMultiple defaultIndex={[]} className="border-transparent">
          {[...tournamentListState.tournaments.entries()]
            .filter(
              (tournament) =>
                tournament.length === 2 &&
                (!tournamentFilter ||
                  tournament[0].includes(tournamentFilter) ||
                  tournament[1].name.toLowerCase().includes(tournamentFilter.toLowerCase())),
            )
            .map(
              (tournament, index: number) =>
                tournament.length == 2 && (
                  <AccordionItem key={index} className="rounded-md bg-gray-800">
                    <h2 className="flex relative">       
                      <AccordionButton className = "flex items-center space-x-100 my-2" >
                        <Box className="flex items-center space-x-4 my-2" flex="1" textAlign="left">
                          <div className="h-full w-6 rounded-lg bg-white/10 bg-gradient-to-br from-blue-700 to-purple-700 aspect-square"></div>
                          <b className="font-display text-4xl">{tournament[1].name}</b>
                          <b>{tournament[0]}</b>
                        </Box>
                        <AccordionIcon/>
                      </AccordionButton>      
                    </h2>
                    
                    <AccordionPanel>
                      <div>
                        <h1 className="font-display font-bold text-2xl">Details</h1>
                        <div className="mb-1 rounded-lg"><b>Created By: </b>{tournament[1].owner}</div>
                        <div className="flex text-center" >
                          <div className="flex justify-between space-x-5">
                            <div className="bg-zinc-900 p-2 rounded-lg w-fit">
                              <b>Start Date:</b> {new Date(tournament[1].startDate?.toNumber() * 1000).toLocaleDateString()}
                            </div>
                            <div className="bg-zinc-900 p-2 rounded-lg w-fit">
                              <b>End Date:</b> {new Date(tournament[1].startDate?.toNumber() * 1000).toLocaleDateString()}
                            </div>
                            <div className="bg-zinc-900 p-2 rounded-lg w-fit">
                              <b>Sport:</b> {sportsId[tournament[1].sportsId]}
                            </div>
                            {tournament[1].isCanceled ? (<div className="bg-red-900 px-6 p-2 rounded-lg w-fit">Canceled</div>)
                              : tournament[1].hasStarted && !tournament[1].hasEnded ? (<div className="bg-yellow-900 px-6 p-2 rounded-lg w-fit">In Progress</div>) 
                              : !tournament[1].hasStarted && !tournament[1].hasEnded ? (<div className="bg-green-900 px-6 p-2 rounded-lg w-fit">Not Yet Started</div>) 
                              : (<div className="bg-orange-900 px-6 p-2 rounded-lg w-fit">Ended</div>) 
                            }                   
                          </div>
                        </div>
                        <h1 className="font-display font-bold text-2xl mt-2">Teams</h1>
                        <div className="mb-4 max-h-64 overflow-scroll overflow-x-hidden">
                          {tournament[1].teamNames?.map((name: string, i: number) => (
                            <button key={i} className="py-2 px-2  mt-2 flex  justify-between w-full bg-white/10 hover:bg-white/30 rounded-md transition-all">
                              <div className="flex space-x-4 items-center">
                              <div className="h-full w-6 rounded-lg bg-white/10 bg-gradient-to-br from-blue-700 to-purple-700 aspect-square"></div>
                                <span>{name}</span>
                              </div>
                            </button>
                          ))}
                        </div>
                      </div>
                      <div className="flex justify-end">
                            <Button onClick={() => {navigator.clipboard.writeText(tournament[0]);}} >
                              <b>Copy Address</b>
                            </Button>
                      </div>
                    </AccordionPanel>
                  </AccordionItem>
                ))}
        </Accordion>)} 
      </>
  );
};

export default TournamentsList;
