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
    gnosis: {
      url: process.env.GNOSIS_MAINNET_RPC_URL || "",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY || "0x0"],
    },
    celo: {
      url: process.env.CELO_MAINNET_RPC_URL || "",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY || "0x0"],
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASE_MAINNET_ETHERSCAN_API_KEY || "",
      base_testnet: process.env.BASE_TESTNET_ETHERSCAN_API_KEY || "",
      gnosis: process.env.GNOSIS_MAINNET_ETHERSCAN_API_KEY || "",
      celo: process.env.CELO_MAINNET_ETHERSCAN_API_KEY || "",
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
      {
        network: "gnosis",
        chainId: 100,
        urls: {
          apiURL: "https://api.gnosisscan.io/api",
          browserURL: "https://gnosisscan.io",
        },
      },
      {
        network: "celo",
        chainId: 42220,
        urls: {
          apiURL: "https://api.celoscan.io/api",
          browserURL: "https://celoscan.io",
        },
      },
    ],
  },
};

export default hhconfig;
