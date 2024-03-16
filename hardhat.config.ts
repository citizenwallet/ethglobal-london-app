import "@openzeppelin/hardhat-upgrades";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config } from "dotenv";
import { parseUnits } from "ethers";

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
    base_mainnet: {
      url: process.env.BASE_MAINNET_RPC_URL,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY || "0x0"],
      gasPrice: Number(parseUnits("30", "gwei")), // this is 30 Gwei
    },
  },
  etherscan: {
    apiKey: {
      base_mainnet: process.env.BASE_MAINNET_ETHERSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "base_mainnet",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
    ],
  },
};

export default hhconfig;
