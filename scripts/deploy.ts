import "@nomicfoundation/hardhat-toolbox";
import { ethers, run } from "hardhat";
import { terminal as term } from "terminal-kit";
import { config } from "dotenv";
import { contractExists } from "./utils/contracts";

async function main() {
  config();

  const entryPointAddress = process.env.ENTRYPOINT_ADDR;
  if (!entryPointAddress) {
    term.red("ENTRYPOINT_ADDR missing in your environment");
    term("\n");
    process.exit();
  }

  const communityEntryPointAddress = process.env.COMMUNITY_ENTRYPOINT_ADDR;
  if (!communityEntryPointAddress) {
    term.red("COMMUNITY_ENTRYPOINT_ADDR missing in your environment");
    term("\n");
    process.exit();
  }

  if (!contractExists(communityEntryPointAddress)) {
    term.red(
      "No contract found at the provided address: %s\n",
      communityEntryPointAddress
    );
    term("\n");
    process.exit();
  }

  term("\n");

  const factory = await ethers.getContractFactory("CardManager");

  console.log("⚙️ deploying CardManager...");

  const deployedContract = await factory.deploy(
    entryPointAddress,
    communityEntryPointAddress,
    []
  );

  console.log("🚀 request sent...");
  await deployedContract.waitForDeployment();

  // wait 2 seconds for the transaction to be mined
  await new Promise((resolve) => setTimeout(resolve, 2000));

  console.log("🧐 verifying...\n");

  try {
    await run("verify:verify", {
      address: await deployedContract.getAddress(),
      constructorArguments: [entryPointAddress, communityEntryPointAddress, []],
    });
  } catch (error: any) {
    console.log("Error verifying contract: %s\n", error && error.message);
  }

  console.log(
    `\nContract deployed at ${await deployedContract.getAddress()}\n`
  );

  process.exit();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
