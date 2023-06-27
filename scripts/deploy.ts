import { Contract } from "ethers";
import { ethers } from "hardhat";
import "dotenv/config";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getAddress()).toString());

  // Deploy the WikiToken
  const WikiTokenFactory = await ethers.getContractFactory("WikiToken");
  const WikiToken = await WikiTokenFactory.deploy(1000000) as any;
  console.log("WikiToken address:", WikiToken.address);


  const walletAddress = process.env.ASSET_POOL_ADDRESS;
  if (!walletAddress) {
    throw new Error("Missing environment variable WALLET_ADDRESS");
  }

  const wikiTokenAddress = WikiToken.address;
  if (!wikiTokenAddress) {
    throw new Error("WikiToken address is not available");
  }

  // Deploy the DAO
  const DAOFactory = await ethers.getContractFactory("DAO");
  const dao = (await DAOFactory.deploy(wikiTokenAddress, walletAddress, 0.1, 0)) as unknown as Contract;
  console.log("DAO address:", dao.address);

  // Lock logic (replace with sdesired lock logic)
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
