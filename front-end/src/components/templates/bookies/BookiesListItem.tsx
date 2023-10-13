import { Heading, Box, Flex, Input, Button, Text, Container, NumberInput, NumberInputField, AccordionItem, AccordionButton, AccordionIcon, AccordionPanel } from '@chakra-ui/react';
import { FC, useReducer, useEffect } from 'react';
import { IBookiesListItem } from './types';
import { ethers } from 'ethers';


const BookiesListItem: FC<IBookiesListItem> = (props: IBookiesListItem) => {
  const { bookieInfo, index } = props;

  return (
      <>{!bookieInfo.isCanceled && (
      <AccordionItem key={index} className="rounded-md bg-gray-700 mb-2">
          <AccordionButton>
            <Box className="  flex items-center space-x-4 my-2" flex="1" textAlign="left">
                <div className="h-full w-6 rounded-lg bg-white/10 bg-gradient-to-br from-blue-700 to-purple-700 aspect-square"></div>
                <b className="font-display text-3xl">{bookieInfo[1].name}</b>{' '}
            </Box>
            <AccordionIcon />
          </AccordionButton>
          <AccordionPanel className="p-4">
            <p><b>Address: </b>{bookieInfo[0]}</p>
            <p><b>Pool: </b> {ethers.utils.formatEther(bookieInfo[1].pool.toNumber())} ETH</p>
          </AccordionPanel>
      </AccordionItem>
      )}</>
  );
};

export default BookiesListItem;
