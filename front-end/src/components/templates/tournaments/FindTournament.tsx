import { Input, Button, Flex, Box } from '@chakra-ui/react';
import { FC, useReducer, useState } from 'react';
import { ITournaments } from './types';
import contractInfo from '../../../../ContractAddresses.json';
import { BorderContainer } from 'components/elements/containers';

// const {
//   bookieFactoryABI,
//   tournamentFactoryABI,
//   tournamentABI,
//   chainlinkTokenABI,
//   bookieABI,
//   diamondABI,
//   diamondAddress,
//   chainlinkTokenAddress,
//   bookiesLibraryAddress,
//   bookiesLibraryABI,
//   bookieFactoryAddress,
//   tournamentFactoryAddress,
// } = contractInfo;

const FindTournament: FC<ITournaments> = (props: ITournaments) => {
  const { tournamentFilter, setTournamentFilter } = props;

  const [findTournamentState, setFindTournamentState] = useReducer(
    (state: any, newState: any) => ({ ...state, ...newState }),
    { tournamentAddress: String, tournamentInfo: [], isLoading: false },
  );

  return (
    <>
      <Box>
        <BorderContainer>
          <div className="flex space-x-8">
            <div className="h-full flex items-center justify-center">
              <img
                className="h-24 w-24 bg-white/20 rounded-2xl object-cover"
                src="https://img.freepik.com/free-vector/geometric-wallpaper_23-2148701210.jpg?w=2000&t=st=1669011322~exp=1669011922~hmac=6d40bd529471d94e461a72f2d17bb5a4b1a312841912ea76ac4f32cf02a513d1"
              ></img>
            </div>
            <div className="flex-auto space-y-4">
              <div>
                <div className="text-3xl font-bold font-display">Search Tournament</div>
                <div>Filter out a tournament by inputting its address.</div>
              </div>
              <Input
                placeholder="Tournament..."
                onChange={(e) => {
                  setFindTournamentState({ tournamentAddress: e.target.value });
                }}
              />
              <Flex justify="right">
                <Button colorScheme="orange" onClick={() => setTournamentFilter && setTournamentFilter(findTournamentState.tournamentAddress)}>Search</Button>
              </Flex>
            </div>
          </div>
        </BorderContainer>
      </Box>
    </>
  );
};

export default FindTournament;
