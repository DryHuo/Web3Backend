import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-etherscan";
import "@nomicfoundation/hardhat-ethers";

if (!process.env.PRIVATE_KEY || !process.env.POLYGONSCAN_API_KEY) {
  throw new Error(
    "Please set your PRIVATE_KEY and POLYSCAN_API_KEY in a .env file"
  );
}

const config: HardhatUserConfig = {
  defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {},
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  },
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};

export default config;
