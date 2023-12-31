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
    wikiToken = (await WikiTokenFactory.deploy(
      ethers.parseEther("1000000000")
    )) as any;
    console.log("WikiToken deployed to:", wikiToken.target);

    // Transfer some tokens to addr1 and addr2
    await wikiToken.transfer(addr1.address, ethers.parseEther("1000"));
    await wikiToken.transfer(addr2.address, ethers.parseEther("1000"));

    // Deploy the Caves contract with the address of the deployed WikiToken
    CaveFactory = await ethers.getContractFactory("Caves");
    caves = (await CaveFactory.deploy(wikiToken.target, deployer)) as any;
    console.log("Caves deployed to:", caves.target);

    const deployerSigner = wikiToken.connect(deployer);
    const addr1Signer = wikiToken.connect(addr1);
    const addr2Signer = wikiToken.connect(addr2);
    const approveTx = await deployerSigner.approve(
      caves.target,
      ethers.parseEther("1000")
    );
    const approveTx2 = await addr1Signer.approve(
      caves.target,
      ethers.parseEther("200")
    );
    const approveTx3 = await addr2Signer.approve(
      caves.target,
      ethers.parseEther("200")
    );
    await approveTx.wait();
    await approveTx2.wait();
    await approveTx3.wait();
  });

  it("Should create a new DAO", async function () {
    await expect(
      await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100)
    )
      .to.emit(caves, "DAOCreated")
      .withArgs("TestDAO", await deployer.getAddress());
  });

  it("Should allow members to join", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(caves.connect(addr1).joinAsMember("TestDAO"))
      .to.emit(caves, "MemberJoined")
      .withArgs("TestDAO", await addr1.getAddress());
  });

  it("Should allow board members to join with stake", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(caves.connect(addr2).joinAsBoardMember("TestDAO", 10))
      .to.emit(caves, "BoardMemberJoined")
      .withArgs("TestDAO", 10, 0, await addr2.getAddress());
  });

  it("Should create a new post", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(
      caves
        .connect(addr1)
        .createPost(
          "TestDAO",
          "First Post!",
          "First Post Contents!",
          [],
          await addr1.getAddress()
        )
    )
      .to.emit(caves, "PostCreated")
      .withArgs("TestDAO", "First Post!", await addr1.getAddress());
  });

  it("Should allow board members to create a proposal", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await expect(
      caves
        .connect(addr2)
        .createProposal(
          "TestDAO",
          "First Proposal!",
          "PublishPost",
          await addr2.getAddress()
        )
    ).to.emit(caves, "ProposalCreated");
  });

  it("Should allow board members to vote on an existing proposal", async function () {
    await caves.connect(deployer).createDAO("TestDAO", "A test DAO", 10, 100);
    await caves.connect(addr1).joinAsBoardMember("TestDAO", 10);
    await caves
      .connect(addr2)
      .createProposal(
        "TestDAO",
        "First Proposal!",
        "PublishPost",
        await addr2.getAddress()
      );
    await expect(caves.connect(addr1).voteProposal("TestDAO", 0, true)).to.emit(
      caves,
      "ProposalVoted"
    );
  });
});
