import { Contract } from "ethers";
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getAddress()).toString());

  // Deploy the WikiToken
  const WikiTokenFactory = await ethers.getContractFactory("WikiToken");
  const wikiToken = (await WikiTokenFactory.deploy(
    ethers.parseEther("1000000")
  )) as Contract; // Replace with desired initial supply
  console.log("WikiToken address:", wikiToken.address);

  // Deploy the DAO
  const DAOFactory = await ethers.getContractFactory("DAO");
  const dao = (await DAOFactory.deploy(wikiToken.address)) as Contract; // This assumes the DAO contract takes the WikiToken's address in the constructor
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
