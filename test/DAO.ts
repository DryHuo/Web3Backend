import { expect } from "chai";
import { ethers } from "hardhat";

describe("DAO", function () {
  let dao: any;

  beforeEach(async function () {
    const initialAssetPool = ethers.parseEther("1000");
    const DAO = await ethers.getContractFactory("DAO");
    let dao = (await DAO.deploy(initialAssetPool))
    await dao.deployed();
  });

  describe("joinAsBoardMember", function () {
    it("should add address to isBoardMember mapping", async function () {
      const [boardMember] = await ethers.getSigners();
      await dao.joinAsBoardMember({ from: boardMember.address });
      expect(await dao.isBoardMember(boardMember.address)).to.be.true;
    });

    it("should revert if address is already a board member", async function () {
      const [boardMember] = await ethers.getSigners();
      await dao.joinAsBoardMember({ from: boardMember.address });
      await expect(dao.joinAsBoardMember({ from: boardMember.address })).to.be.revertedWith(
        "Already a board member"
      );
    });

    it("should revert if address is already a regular member", async function () {
      const [regularMember] = await ethers.getSigners();
      await dao.joinAsRegularMember({ from: regularMember.address });
      await expect(dao.joinAsBoardMember({ from: regularMember.address })).to.be.revertedWith(
        "Already a regular member"
      );
    });
  });

  describe("joinAsRegularMember", function () {
    it("should add address to isMember mapping", async function () {
      const [regularMember] = await ethers.getSigners();
      await dao.joinAsRegularMember({ from: regularMember.address });
      expect(await dao.isMember(regularMember.address)).to.be.true;
    });

    it("should revert if address is already a regular member", async function () {
      const [regularMember] = await ethers.getSigners();
      await dao.joinAsRegularMember({ from: regularMember.address });
      await expect(dao.joinAsRegularMember({ from: regularMember.address })).to.be.revertedWith(
        "Already a regular member"
      );
    });

    it("should revert if address is already a board member", async function () {
      const [boardMember] = await ethers.getSigners();
      await dao.joinAsBoardMember({ from: boardMember.address });
      await expect(dao.joinAsRegularMember({ from: boardMember.address })).to.be.revertedWith(
        "Already a board member"
      );
    });
  });

  describe("makeProposal", function () {
    it("should add a new proposal to the proposals array", async function () {
      const [boardMember] = await ethers.getSigners();
      const description = "Test proposal";
      await dao.joinAsBoardMember({ from: boardMember.address });
      await dao.makeProposal(description, { from: boardMember.address });
      const proposal = await dao.proposals(0);
      expect(proposal.description).to.equal(description);
      expect(proposal.proposer).to.equal(boardMember.address);
      expect(proposal.isAccepted).to.be.false;
      expect(proposal.totalVotes).to.equal(0);
    });

    it("should revert if caller is not a member of DAO", async function () {
      const [nonMember] = await ethers.getSigners();
      const description = "Test proposal";
      await expect(dao.makeProposal(description, { from: nonMember.address })).to.be.revertedWith(
        "Not a member of DAO"
      );
    });
  });

  describe("vote", function () {
    it("should add a vote to the specified proposal", async function () {
      const [boardMember] = await ethers.getSigners();
      const description = "Test proposal";
      await dao.joinAsBoardMember({ from: boardMember.address });
      await dao.makeProposal(description, { from: boardMember.address });
      await dao.vote(0, true, { from: boardMember.address });
      const proposal = await dao.proposals(0);
      expect(proposal.totalVotes).to.equal(1);
      expect(proposal.votes[boardMember.address]).to.be.true;
    });

    it("should set isAccepted to true if accept is true", async function () {
      const [boardMember] = await ethers.getSigners();
      const description = "Test proposal";
      await dao.joinAsBoardMember({ from: boardMember.address });
      await dao.makeProposal(description, { from: boardMember.address });
      await dao.vote(0, true, { from: boardMember.address });
      const proposal = await dao.proposals(0);
      expect(proposal.isAccepted).to.be.true;
    });

    it("should set isAccepted to false if accept is false", async function () {
      const [boardMember] = await ethers.getSigners();
      const description = "Test proposal";
      await dao.joinAsBoardMember({ from: boardMember.address });
      await dao.makeProposal(description, { from: boardMember.address });
      await dao.vote(0, false, { from: boardMember.address });
      const proposal = await dao.proposals(0);
      expect(proposal.isAccepted).to.be.false;
    });

    it("should revert if caller is not a board member", async function () {
      const [regularMember] = await ethers.getSigners();
      const description = "Test proposal";
      await dao.joinAsRegularMember({ from: regularMember.address });
      await dao.makeProposal(description, { from: regularMember.address });
      await expect(dao.vote(0, true, { from: regularMember.address })).to.be.revertedWith(
        "Only board members can vote"
      );
    });

    it("should revert if caller has already voted", async function () {
      const [boardMember] = await ethers.getSigners();
      const description = "Test proposal";
      await dao.joinAsBoardMember({ from: boardMember.address });
      await dao.makeProposal(description, { from: boardMember.address });
      await dao.vote(0, true, { from: boardMember.address });
      await expect(dao.vote(0, true, { from: boardMember.address })).to.be.revertedWith(
        "Already voted"
      );
    });
  });
});