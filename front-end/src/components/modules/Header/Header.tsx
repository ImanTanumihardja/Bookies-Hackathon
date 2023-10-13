import { Box, Container, Flex, HStack, Heading } from '@chakra-ui/react';
import { ColorModeButton, NavBar } from 'components/elements';
import { ConnectButton } from '../ConnectButton';

const Header = () => {
  return (
    <Box borderBottom="1px" borderBottomColor="chakra-border-color">
      <Container maxW="container.xl" p={'10px'}>
        <Flex align="center" justify="space-between">
          <Heading size="lg">Bookies</Heading>
          <NavBar />
          <HStack gap={'10px'}>
            <ConnectButton />
            {/* <ColorModeButton /> */}
          </HStack>
        </Flex>
      </Container>
    </Box>
  );
};

export default Header;
