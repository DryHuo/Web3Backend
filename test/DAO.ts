import { expect } from "chai";
import { ethers } from "hardhat";

describe("Caves", function () {
  let WikiTokenFactory: any;
  let wikiToken: any;
  let CaveFactory: any;
  let caves: any;
  let deployer: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async () => {
    // Get the ContractFactory and Signers here
    WikiTokenFactory = await ethers.getContractFactory("WikiToken");
    [deployer, addr1, addr2] = await ethers.getSigners();

    // Deploy the contract and get its instance
    wikiToken = (await WikiTokenFactory.deploy(10000)) as any;
    console.log("WikiToken deployed to:", wikiToken.target);

    // Deploy the Caves contract with the address of the deployed WikiToken
    CaveFactory = await ethers.getContractFactory("Caves");
    caves = (await CaveFactory.deploy(wikiToken.target, deployer)) as any;
    console.log("Caves deployed to:", caves.target);

    const deployerSigner = wikiToken.connect(deployer);
    const addr1Signer = wikiToken.connect(addr1);
    const addr2Signer = wikiToken.connect(addr2);
    const approveTx = await deployerSigner.approve(caves.target, "90000000000000000000");
    const approveTx2 = await addr1Signer.approve(caves.target, "90000000000000000000");
    const approveTx3 = await addr2Signer.approve(caves.target, "90000000000000000000");
    await approveTx.wait();
    await approveTx2.wait();
    await approveTx3.wait();
  });

  it("Should create a new DAO", async function () {
    await expect(
      caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100)
    )
      .to.emit(caves, "DAOCreated")
      .withArgs(1, await deployer.getAddress(), "TestDAO");
  });

  it("Should allow members to join", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(caves.connect(addr1).joinAsMember(1))
      .to.emit(caves, "MemberJoined")
      .withArgs(1, await addr1.getAddress());
  });

  it("Should allow board members to join with stake", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(caves.connect(addr2).joinAsBoardMember(1, 20))
      .to.emit(caves, "BoardMemberJoined")
      .withArgs(1, await addr2.getAddress(), 20);
  });

  it("Should create a new post", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(
      caves
        .connect(addr1)
        .createPost(1, "First Post!", [], await addr1.getAddress())
    )
      .to.emit(caves, "PostCreated")
      .withArgs(1, 1);
  });

  it("Should allow board members to create a proposal", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(
      caves
        .connect(addr2)
        .createProposal(1, "First Proposal!", await addr2.getAddress())
    )
      .to.emit(caves, "ProposalCreated")
      .withArgs(1, 1);
  });

  it("Should allow board members to vote on a proposal", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await caves.connect(addr2).joinAsBoardMember(1, 20);
    await caves
      .connect(addr2)
      .createProposal(1, "First Proposal!", await addr2.getAddress());
    await expect(caves.connect(addr2).voteProposal(1, 0, true))
      .to.emit(caves, "VoteRecorded")
      .withArgs(1, 0, await addr2.getAddress(), true);
  });
});
