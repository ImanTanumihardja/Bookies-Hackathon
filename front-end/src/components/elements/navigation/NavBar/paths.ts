import { ISubNav } from '../SubNav/SubNav';

const NAV_LINKS: ISubNav[] = [
  { label: 'Home', href: '/' },
  {
    label: 'Tournaments',
    href: '/tournaments',
  },
  {
    label: 'Bookies',
    href: '/bookies',
  },
  // {
    //   label: 'Transactions',
    //   href: '/transactions',
    // children: [
    //   {
    //     label: 'ERC20',
    //     subLabel: 'Get your ERC20 transfers',
    //     href: '/transfers/erc20',
    //     logo: 'token',
    //   },
    //   {
    //     label: 'NFT',
    //     subLabel: 'Get your ERC721 an ERC1155 transfers',
    //     href: '/transfers/nft',
    //     logo: 'lazyNft',
    //   },
    // ],
  // },
  // {
  //   label: 'Balances',
  //   href: '/balances',
  //   children: [
  //     {
  //       label: 'ERC20',
  //       subLabel: 'Get your ERC20 balances',
  //       href: '/balances/erc20',
  //       logo: 'token',
  //     },
  //     {
  //       label: 'NFT',
  //       subLabel: 'Get your ERC721 an ERC1155 balances',
  //       href: '/balances/nft',
  //       logo: 'pack',
  //     },
  //   ],
  // },
];

export default NAV_LINKS;
