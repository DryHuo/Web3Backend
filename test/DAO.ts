import { expect } from "chai";
import { ethers } from "hardhat";

describe("Caves", function () {
  let WikiToken: any;
  let wikiToken: any;
  let Caves: any;
  let caves: any;
  let deployer: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async () => {
    // Get the ContractFactory and Signers here
    WikiToken = await ethers.getContractFactory("WikiToken");
    [deployer, addr1, addr2] = await ethers.getSigners();

    // Deploy the contract and get its instance
    wikiToken = await WikiToken.connect(deployer).deploy(10000);
    await wikiToken.deployed();

    // Deploy the Caves contract with the address of the deployed WikiToken
    Caves = await ethers.getContractFactory("Caves");
    caves = await Caves.connect(deployer).deploy(
      wikiToken.address,
      deployer.address
    );
    await caves.deployed();
  });

  it("Should set the right owner", async function () {
    expect(await caves._taxAccount()).to.equal(deployer.address);
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
