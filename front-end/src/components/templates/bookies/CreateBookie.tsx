import { Input, Button, Flex, Box, useDisclosure, InputGroup, InputRightAddon, useToast, Collapse } from '@chakra-ui/react';
import { FC, useReducer } from 'react';
import contractInfo from '../../../../ContractAddresses.json';
import { prepareWriteContract, readContract, writeContract } from '@wagmi/core';
import { ethers } from 'ethers';
import { BorderContainer } from 'components/elements/containers';
import { useAccount } from 'wagmi';

const {
  bookieFactoryABI,
  tournamentABI,
  chainlinkTokenABI,
  bookieABI,
  bookiesLibraryABI,
  chainlinkTokenAddress,
  bookiesLibraryAddress,
  tournamentFactoryAddress,
  bookieFactoryAddress
} = contractInfo;

const CreateBookie: FC = () => {
  const [createBookieState, setCreateBookieState] = useReducer(
    (state: any, newState: any) => ({ ...state, ...newState }),
    { name: '', buyInPrice: 0, tournamentAddress: String, gasLimit: 500000, isLoading: false },
  );

  const { isOpen, onToggle } = useDisclosure();
  const toast = useToast()
  const { isConnected } = useAccount()

  const createBookie = async () => {
    if (!isConnected) {
      toast({
        title: 'Oops, something is wrong...',
        description: "Please connect wallet",
        status: 'error',
        position: 'top-right',
        isClosable: true,
      });
      return
    }

    setCreateBookieState({ isLoading: true });
    try {
      const tournamentInfo: any = await readContract({
        address: createBookieState.tournamentAddress,
        abi: tournamentABI,
        functionName: 'getTournamentInfo',
      });

      const [registryFundingAmount, totalAPIRequestFee]: any = await readContract({
        address: bookiesLibraryAddress,
        abi: bookiesLibraryABI,
        functionName: 'calculateLinkPayment',
        args: [
          tournamentInfo.endDate - tournamentInfo.startDate,
          tournamentInfo.updateInterval,
          tournamentInfo.gameCount,
          0,
          createBookieState.gasLimit,
        ],
      });

      const approveConfig = await prepareWriteContract({
        address: chainlinkTokenAddress,
        abi: chainlinkTokenABI,
        functionName: 'approve',
        args: [bookieFactoryAddress, registryFundingAmount + totalAPIRequestFee],
      });

      const approveTx = await writeContract(approveConfig);
      await approveTx.wait();

      console.log("Approved")

      const createBookieConfig = await prepareWriteContract({
        address: bookieFactoryAddress,
        abi: bookieFactoryABI,
        functionName: 'createBookie',
        args: [
          createBookieState.name,
          createBookieState.buyInPrice,
          createBookieState.tournamentAddress,
          createBookieState.gasLimit,
        ],
      });

      const createBookieTx = await writeContract(createBookieConfig);
      await createBookieTx.wait();
    } catch (error) {
      console.error(error);
    }
    setCreateBookieState({ isLoading: false });
  };

  return (
    <>
      <BorderContainer className="cursor-pointer">
        <div onClick={onToggle} className="flex justify-between items-center">
          <div>
            <div className="text-3xl font-bold font-display">Create a Bookie!</div>
            <div> Create a bookie to start betting on tournaments.</div>
          </div>
          {isOpen ? 
            <Button onClick={onToggle} className="bg-blue-700 mt-5 py-2 px-8 rounded-lg cursor-pointer" variant="solid">
              Close
            </Button> :
            <Button colorScheme="orange" onClick={onToggle} className="bg-blue-700 mt-5 py-2 px-8 rounded-lg cursor-pointer" variant="solid">
              Start Creating
            </Button>
          }
        </div>
          <Collapse in={isOpen} className="space-y-4 mt-4">
            <div>
              <h1 className="font-display font-bold mb-2">Name</h1>
              <Input
                placeholder="The World Cup"
                onChange={(e) => {
                  setCreateBookieState({ name: e.target.value });
                }}
              />
            </div>
            <div>
              <h1 className="font-display font-bold mb-2">Buy-In Price</h1>
                <InputGroup>
                  <Input
                    placeholder="1"
                    onChange={(e) => {
                      setCreateBookieState({ buyInPrice: ethers.utils.parseEther(e.target.value) });
                    }}
                  />
                  <InputRightAddon children='ETH' />
                </InputGroup>
            </div>

            <div>
              <h1 className="font-display font-bold mb-2">Tournament Address</h1>
              <Input
                placeholder="0x0000000000000000000000000000000000000000"
                onChange={(e) => {
                  setCreateBookieState({ tournamentAddress: e.target.value });
                }}
              />
            </div>
            <Flex>
              <Button isLoading={createBookieState.isLoading} colorScheme="orange" onClick={createBookie}>
                Create
              </Button>
            </Flex>
          </Collapse>
      </BorderContainer>
    </>
  );
};

export default CreateBookie;
