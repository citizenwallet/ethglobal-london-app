import "@openzeppelin/hardhat-upgrades";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config } from "dotenv";

config();

const hhconfig: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      evmVersion: "paris",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    base: {
      url: process.env.BASE_MAINNET_RPC_URL,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY || "0x0"],
    },
    base_testnet: {
      url: process.env.BASE_TESTNET_RPC_URL,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY || "0x0"],
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASE_MAINNET_ETHERSCAN_API_KEY || "",
      base_testnet: process.env.BASE_TESTNET_ETHERSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "base_testnet",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org/",
        },
      },
    ],
  },
};

export default hhconfig;
