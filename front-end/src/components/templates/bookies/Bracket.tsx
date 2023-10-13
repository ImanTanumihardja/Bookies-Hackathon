import { Heading, Box, Flex, Input, Button, Text, Container, NumberInput, NumberInputField, AccordionItem, AccordionButton, AccordionIcon, AccordionPanel, useToast } from '@chakra-ui/react';
import { FC, useReducer, useEffect } from 'react';
import { prepareWriteContract, readContract, writeContract } from '@wagmi/core';
import { IBookiePannel, IBracket } from './types';
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

interface Team {
  teamName: string;
  wins: number;
}

interface Pair {
  team1: Team;
  team2: Team;
}

interface Props {
  teams: Team[];
}

const Bracket: FC<IBracket> = (props: IBracket) => {
  const { bookieState, setBookieState} = props;

  const rounds = Math.ceil(Math.log2(bookieState.tournamentInfo.teamNames.length));

  // Generate an initial bracket with empty slots
  let bracket: Pair[][] = Array.from({ length: rounds }, () => []);
  
  // Fill the initial round with teams
  bracket[0] = bookieState.tournamentInfo.teamNames.reduce((acc: Pair[], teamName: string, index:number, arr: any[]) => {
    if (index % 2 === 0) {
      const team1: Team = {teamName, wins: bookieState.bracket[index]}
      const team2: Team = {teamName: bookieState.tournamentInfo.teamNames[index + 1], wins: bookieState.bracket[index+1]}
      const pair: Pair = { team1, team2 };
      acc.push(pair);
    }
    return acc;
  }, []);

  // Generate subsequent rounds by pairing teams
  for (let round = 0; round < rounds - 1; round++) {
    bracket[round + 1] = bracket[round].reduce((acc: Pair[], team, index:number, arr) => {
      if (index % 2 === 0) {
        const pair: Pair = { team1: team, team2: arr[index + 1] };
        acc.push(pair);
      }
      return acc;
    }, []);
  }

  return (
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
  );
};

export default Bracket;
