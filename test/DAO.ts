import { expect } from "chai";
import { ethers } from "hardhat";

describe("DAO", function () {
  let DAO: any;
  let dao: any;
  let deployer: any;
  let boardMember: any;
  let regularMember: any;

  beforeEach(async () => {
    // Get the ContractFactory and Signers here
    DAO = await ethers.getContractFactory("DAO");
    [deployer, boardMember, regularMember] = await ethers.getSigners();

    // Deploy the contract and get its instance
    dao = await DAO.connect(deployer).deploy(10000);
    await dao.deployed();
  });

  it("Should set the right owner and initial asset pool", async function () {
    expect(await dao.owner()).to.equal(deployer.address);
    expect(await dao.totalAssetPool()).to.equal(10000);
  });

  it("Should allow a person to join as a board member", async function () {
    await dao.connect(boardMember).joinAsBoardMember();
    expect(await dao.isBoardMember(boardMember.address)).to.equal(true);
  });

  it("Should allow a person to join as a regular member", async function () {
    await dao.connect(regularMember).joinAsRegularMember();
    expect(await dao.isMember(regularMember.address)).to.equal(true);
  });

  it("Should allow a member to make a proposal", async function () {
    await dao.connect(regularMember).joinAsRegularMember();
    await dao.connect(regularMember).makeProposal("Test Proposal");
    expect((await dao.proposals(0)).description).to.equal("Test Proposal");
  });

  it("Should allow a board member to vote on a proposal", async function () {
    await dao.connect(regularMember).joinAsRegularMember();
    await dao.connect(boardMember).joinAsBoardMember();
    await dao.connect(regularMember).makeProposal("Test Proposal");
    await dao.connect(boardMember).vote(0, true);
    expect((await dao.proposals(0)).totalVotes).to.equal(1);
    expect((await dao.proposals(0)).isAccepted).to.equal(true);
  });
});
