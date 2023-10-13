import { ChakraProvider } from '@chakra-ui/react';
import { createClient, configureChains, WagmiConfig, chain } from 'wagmi';
import { extendTheme } from '@chakra-ui/react';
import { publicProvider } from 'wagmi/providers/public';
import { SessionProvider } from 'next-auth/react';
import type { AppProps } from 'next/app';
import { getDefaultWallets, RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import '../styles/globals.css';
import Head from 'next/head';

const { provider, webSocketProvider } = configureChains(
  [chain.goerli, chain.polygonMumbai],
  [alchemyProvider({ apiKey: 'cqvNfgq6Y3U2YQnttqH9Jmfl7qpjHsaX' }), publicProvider()],
);

const { connectors } = getDefaultWallets({
  appName: 'Bookies',
  chains: [chain.goerli, chain.polygonMumbai],
});

const client = createClient({
  provider,
  webSocketProvider,
  autoConnect: true,
  connectors,
});

const config = {
  initialColorMode: 'dark',
  useSystemColorMode: false,
};

const theme = extendTheme({ config });

const MyApp = ({ Component, pageProps }: AppProps) => {
  return (
    <ChakraProvider resetCSS theme={theme}>
      <Head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" />
        <link href="https://fonts.googleapis.com/css2?family=Signika&display=swap" rel="stylesheet" />
      </Head>
      <WagmiConfig client={client}>
        <SessionProvider session={pageProps.session} refetchInterval={0}>
          <RainbowKitProvider theme={darkTheme()} chains={[chain.goerli, chain.polygonMumbai]}>
            <Component {...pageProps} />
          </RainbowKitProvider>
        </SessionProvider>
      </WagmiConfig>
    </ChakraProvider>
  );
};

export default MyApp;
