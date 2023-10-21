import {
  Box,
  Accordion,
  AccordionButton,
  AccordionItem,
  AccordionPanel,
  AccordionIcon,
  Center,
  Spinner,
} from '@chakra-ui/react';
import { FC, useEffect, useReducer } from 'react';
import { readContract } from '@wagmi/core';
import contractInfo from '../../../../ContractAddresses.json';
import { useContractEvent } from 'wagmi';
import { BorderContainer } from 'components/elements/containers';
import { ethers } from 'ethers';
import BookiesListItem from './BookiesListItem';

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

const BookiesList: FC = () => {
  const [bookiesListState, setBookiesListState] = useReducer(
    (state: any, newState: any) => ({ ...state, ...newState }),
    { bookies: new Map(), isLoading: false },
  );

  useEffect(() => {
    getBookies();
  }, []);

  useContractEvent({
    address: bookieFactoryAddress,
    abi: bookieFactoryABI,
    eventName: 'NewBookie',
    listener: (event) => {
      getBookies();
      console.log(event);
    },
  });

  const getBookies = async () => {

    setBookiesListState({ isLoading: true })
    try {
      const bookieAddresses: string[] = (await readContract({
        address: bookieFactoryAddress,
        abi: bookieFactoryABI,
        functionName: 'getBookies',
      })) as string[];
      console.log(bookieAddresses);


      // Get tournament info
      var bookies = new Map();
      for (const address of bookieAddresses) {
        const bookieInfo = await readContract({
          address: address,
          abi: bookieABI,
          functionName: 'getBookieInfo',
        });
        bookies.set(address, bookieInfo);
      }
      setBookiesListState({ bookies });
    } catch (error) {
      console.error(error);
    }
    setBookiesListState({ isLoading: false })
  };

  return (
        <BorderContainer>
        <div className="mb-4">
            <div className="text-3xl font-bold font-display">Explore Bookies</div>
            <div>Find a Bookie to create a bracket.</div>
        </div>
        {(bookiesListState.isLoading ? <Center><Spinner size='xl'/></Center> :
            <Accordion allowMultiple defaultIndex={[]} className="border-transparent">
                {[...bookiesListState.bookies.entries()].map(
                (bookieInfo, index: number) =>
                  <BookiesListItem {...{bookieInfo, index}} key={index}/>
                )}
            </Accordion>)}
        </BorderContainer>
  );
};

export default BookiesList;
