import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

if (!process.env.PRIVATE_KEY || !process.env.ETHERSCAN_API_KEY) {
  throw new Error(
    "Please set your PRIVATE_KEY and ETHERSCAN_API_KEY in a .env file"
  );
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/Y8SzPXM7p-3VEe5rdg_W4BaJ2pS-1sbh",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
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
