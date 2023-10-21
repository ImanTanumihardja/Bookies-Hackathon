import { Heading, Box, Flex, Input, Button, Text, Container, NumberInput, NumberInputField, AccordionItem, AccordionButton, AccordionIcon, AccordionPanel, useToast } from '@chakra-ui/react';
import { FC, useReducer, useEffect } from 'react';
import { prepareWriteContract, readContract, writeContract } from '@wagmi/core';
import { IBookiePannel } from './types';
import { ethers } from 'ethers';
import { useAccount } from 'wagmi';
import { sportsId } from 'utils/sportsId';
import contractInfo from '../../../../ContractAddresses.json';

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

const Bookie: FC<IBookiePannel> = (props: IBookiePannel) => {
  const { bookieState, setBookieState} = props;

  const { address: userAddress } = useAccount()
  const toast = useToast()
  const { isConnected } = useAccount()

  const cancelBookie = async () => {
    try {
      const cancelBookieConfig: any = await prepareWriteContract({
        address: bookieState.bookieAddress,
        abi: bookieABI,
        functionName: 'cancelBookie',
      });

      const txn = await writeContract(cancelBookieConfig);
      await txn.wait();
    } catch (error) {
      console.log;
    }
  };

  const cancelBracket = async () => {
    try {
      const cancelBracketConfig: any = await prepareWriteContract({
        address: bookieState.bookieAddress,
        abi: bookieABI,
        functionName: 'cancelBracket',
      });

      const txn = await writeContract(cancelBracketConfig);
      await txn.wait();
    } catch (error) {
      console.log;
    }
  };

  const collectPayout = async () => {
    try {
      const collectPayoutConfig: any = await prepareWriteContract({
        address: bookieState.bookieAddress,
        abi: bookieABI,
        functionName: 'collectPayout',
      });

      const txn = await writeContract(collectPayoutConfig);
      await txn.wait();
    } catch (error) {
      console.log;
    }
  };

  const createBracket = async () => {
    try {
      const createBracketConfig: any = await prepareWriteContract({
        address: bookieState.bookieAddress,
        abi: bookieABI,
        functionName: 'createBracket',
        args: [bookieState.bracket],
        overrides: {
          value: bookieState.bookieInfo.buyInPrice,
        },
      });

      await writeContract(createBracketConfig);
    } catch (error) {
      console.error(error);
    }
  };

  return (
      <Box borderRadius={5} className="bg-gray-800 p-6 space-y-4">
      <Box className="flex items-center space-x-4 my-2" flex="1" textAlign="left">
        <Text className="font-display font-bold text-3xl">{bookieState.bookieInfo.name}</Text>
        <Text className="font-display"> {bookieState.bookieAddress}</Text>
      </Box>
      <div>
        <h1 className="font-display font-bold text-2xl">Details</h1>
        <Text className="mb-2"><b>Tournament Address: </b>{bookieState.bookieInfo.tournamentAddress.toString()}</Text>

        <div className="flex gap-4 items-center text-center">
          <div className="bg-zinc-900 w-fit rounded-lg p-2">
            <span><b>Buy-in Price: </b>{ethers.utils.formatEther(bookieState.bookieInfo.buyInPrice)} ETH</span>
          </div>
          <div className="bg-zinc-900 w-fit rounded-lg p-2">
            <span><b>Pool Size: </b>{ethers.utils.formatEther(bookieState.bookieInfo.pool)} ETH</span>
          </div>
          {bookieState.bookieInfo.isCanceled ? (<div className="bg-red-900 px-6 p-2 rounded-lg w-fit font-bold">Canceled</div>)
            : bookieState.bookieInfo.hasStarted && !bookieState.bookieInfo.hasEnded ? (<div className="bg-yellow-900 px-6 p-2 rounded-lg w-fit font-bold">In Progress</div>) 
            : !bookieState.bookieInfo.hasStarted && !bookieState.bookieInfo.hasEnded ? (<div className="bg-green-900 px-6 p-2 rounded-lg w-fit font-bold">Open</div>) 
            : (<div className="bg-orange-900 px-6 p-2 rounded-lg w-fit font-bold">Ended</div>)}
        </div>
      </div>

      {isConnected && (
        <div>
          <Heading marginTop={5} size="md">
            Your Bracket
          </Heading>
          <div className="grid grid-cols-4">
            {bookieState.tournamentInfo.teamNames.map((value: number, index: number) => (
              <Container key={index} margin={2}>
                <Text>{value}</Text>
                <NumberInput
                  size="xs"
                  maxW={16}
                  min={0}
                  value={bookieState.bracket[index]}
                  isDisabled={bookieState.bookieInfo.hasStarted}
                  onChange={(e) => {
                    bookieState.bracket[index] = e;
                    setBookieState({ bracket: bookieState.bracket });
                  }}
                >
                  <NumberInputField placeholder={'0'} borderRadius={5} backgroundColor="black" />
                </NumberInput>
              </Container>
            ))}
          </div>

          <Flex justify="right">
            {((bookieState.bookieInfo.owner != userAddress && !bookieState.bookieInfo.hasStarted &&
              <Button colorScheme="orange" margin={2} onClick={cancelBookie}>
                Cancel Bookie
              </Button>
            ))}
            {((!bookieState.bookieInfo.hasStarted &&
              <Button colorScheme="orange" margin={2} onClick={createBracket}>
                Create Bracket
              </Button>
            ))}
            {((bookieState.hasBracket && !bookieState.bookieInfo.hasStarted &&
              <Button colorScheme="orange" margin={2} onClick={cancelBracket}>
                Cancel Bracket
              </Button>
            ))}
            {((bookieState.hasBracket && bookieState.bookieInfo.hasEnded && bookieState.bookieInfo.hasStarted &&
              <Button colorScheme="green" margin={2} onClick={collectPayout}>
                Claim Payout
              </Button>
            ))}
          </Flex>
      </div>)}
    </Box>
  );
};

export default Bookie;
