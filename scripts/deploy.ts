import { Contract, ContractTransaction } from "ethers";
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getAddress()).toString());

  // Deploy the WikiToken
  const WikiTokenFactory = await ethers.getContractFactory("WikiToken");
  const wikiToken = await WikiTokenFactory.deploy(10000)
  console.log("WikiToken", wikiToken.target);

  // Deploy the DAO
  const TaxAccount = process.env.TAX_ACOUNT || "";
  const CaveFactory = await ethers.getContractFactory("Caves");
  const cave = await CaveFactory.deploy(wikiToken.target, TaxAccount) as any;
  console.log("DAO", cave.target);

  // Lock logic (replace with desired lock logic)
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;
  const lockedAmount = ethers.parseEther("0.001");

  const Lock = await ethers.getContractFactory("Lock");
  const lock = await Lock.deploy(unlockTime, { value: lockedAmount });
  console.log(
    `Lock with ${ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
