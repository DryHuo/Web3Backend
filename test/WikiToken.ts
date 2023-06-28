import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("WikiToken", function () {
  let WikiTokenFactory;
  let wikiToken: Contract;
  let owner: any;
  let addr1: any;
  let addr2: any;
  let addrs: any;

  beforeEach(async function () {
    WikiTokenFactory = await ethers.getContractFactory("WikiToken");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // Deploy contract and initial supply of 1000 tokens
    wikiToken = await WikiTokenFactory.deploy(ethers.parseEther("1000"));
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await wikiToken.hasRole(await wikiToken.DEFAULT_ADMIN_ROLE(), owner.address)).to.equal(true);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await wikiToken.balanceOf(owner.address);
      console.log("Owner balance is", ownerBalance.toString());
      expect(await wikiToken.totalSupply()).to.equal(ownerBalance);
      expect(ownerBalance).to.equal(ethers.parseEther("1000"));
    });
  });

  describe("Transactions", function () {
    it("Should fail if sender doesn't have minter role", async function () {
      const initialOwnerBalance = await wikiToken.balanceOf(owner.address);

      try {
        await wikiToken.mint(addr1.address, ethers.parseEther("50"));
      } catch (error: any) {
        expect(error.message).to.include('missing role');
      }

      expect(await wikiToken.balanceOf(owner.address)).to.equal(initialOwnerBalance);
    });

    it("Should update balances after transfers", async function () {
      const initialOwnerBalance = await wikiToken.balanceOf(owner.address);
      expect(await wikiToken.balanceOf(addr1.address)).to.equal(0);
      // Transfer 100 tokens from owner to addr1
      await wikiToken.transfer(addr1.address, ethers.parseEther("100"));

      // Check balances
      expect(await wikiToken.balanceOf(owner.address)).to.equal(initialOwnerBalance - ethers.parseEther("100"));
      expect(await wikiToken.balanceOf(addr1.address)).to.equal(ethers.parseEther("100"));
    });

    it("Minter should be able to mint new tokens", async function () {
      const initialOwnerBalance = await wikiToken.balanceOf(owner.address);

      // Mint 100 new tokens
      await wikiToken.mint(owner.address, ethers.parseEther("100"));

      expect(await wikiToken.balanceOf(owner.address)).to.equal(initialOwnerBalance + ethers.parseEther("100"));
      expect(await wikiToken.totalSupply()).to.equal(initialOwnerBalance + ethers.parseEther("100"));
    });
  });
});
