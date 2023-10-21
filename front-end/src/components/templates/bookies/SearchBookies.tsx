import {
  Heading,
  Input,
  Button,
  Flex,
  Box,
  Text,
  Container,
  NumberInput,
  NumberInputField,
  useToast,
} from '@chakra-ui/react';
import { FC, useEffect, useReducer } from 'react';
import contractInfo from '../../../../ContractAddresses.json';
import { prepareWriteContract, readContract, writeContract } from '@wagmi/core';
import { ethers } from 'ethers';
import { BorderContainer } from 'components/elements/containers';
import { useAccount } from 'wagmi';
import { sportsId } from 'utils/sportsId';
import BookiePannel from './BookiePannel';

const {
  bookieFactoryABI,
  tournamentABI,
  chainlinkTokenABI,
  bookieABI,
  chainlinkTokenAddress,
  bookiesLibraryAddress,
  tournamentFactoryAddress,
  bookieFactoryAddress
} = contractInfo;

const SearchBookies: FC = (props) => {
  const [searchBookieState, setSearchBookieState] = useReducer((state: any, newState: any) => ({ ...state, ...newState }), {
    bookieAddress: "",
    bookieInfo: [],
    tournamentInfo: [],
    bracket: [],
    hasBracket: false,
    isLoading: false,
  });

  const { address: userAddress } = useAccount()
  const toast = useToast()
  const { isConnected } = useAccount()

  useEffect(() => {
    setSearchBookieState({
      bookieAddress: "",
      bookieInfo: [],
      tournamentInfo: [],
      bracket: [],
      hasBracket: false,
      isLoading: false,
    })
  }, [isConnected])

  const findBookie = async () => {
    setSearchBookieState({ isLoading: true });
    setSearchBookieState({ bookieInfo: [] });
    try {
      // Get bookie info
      const bookieInfo: any = await readContract({
        address: searchBookieState.bookieAddress,
        abi: bookieABI,
        functionName: 'getBookieInfo',
      });

      console.log(bookieInfo)

      // Get tournament info
      const tournamentInfo: any = await readContract({
        address: bookieInfo.tournamentAddress,
        abi: tournamentABI,
        functionName: 'getTournamentInfo',
      });

      setSearchBookieState({ tournamentInfo: tournamentInfo, bookieInfo: bookieInfo });

      // Get bracket
      if (isConnected)
      {
        const bracket: any = await readContract({
          address: searchBookieState.bookieAddress,
          abi: bookieABI,
          functionName: 'getBracket',
          args: [userAddress],
        });
  
        if (bracket.length !== 0) {
          setSearchBookieState({ bracket: [...bracket], hasBracket: true });

        } else {
          setSearchBookieState({ bracket: Array(tournamentInfo.teamNames.length).fill(0) });
        }
      }
    } catch (error) {
      console.error(error);
    }
    setSearchBookieState({ isLoading: false });
  };

  return (
    <Box className="space-y-6 ">
      <BorderContainer>
        <div className="flex space-x-8">
          <div className="flex-auto space-y-4">
            <div>
              <div className="text-3xl font-bold font-display">Search Bookie</div>
              <div>Search the address to a bookie to create a bracket and get more details.</div>
            </div>
            <Input
              placeholder="Bookie..."
              value={searchBookieState.bookieAddress}
              onChange={(e) => {
                setSearchBookieState({ bookieAddress: e.target.value });
              }}
            />
            <Button colorScheme="orange" variant="solid" isLoading={searchBookieState.isLoading} onClick={findBookie}>
              Search
            </Button>
          </div>
        </div>
      </BorderContainer>

      {searchBookieState.bookieInfo.length != 0 && (
        <BookiePannel {...{bookieState: searchBookieState, setBookieState: setSearchBookieState}}/>
      )}
    </Box>
  );
};

export default SearchBookies;
