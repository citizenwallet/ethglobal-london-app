import { ethers } from "hardhat";

export async function contractExists(address: string) {
  const provider = ethers.getDefaultProvider();
  const bytecode = await provider.getCode(address);

  return bytecode !== "0x";
}
