import { expect } from "chai";
import EntryPointArtifact from "@account-abstraction/contracts/artifacts/EntryPoint.json";
import "@nomicfoundation/hardhat-toolbox";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { config } from "dotenv";
import { ethers, upgrades } from "hardhat";

describe("CardManager", function () {
  config();

  async function deployCardManagerFixture() {
    const [
      owner,
      friend1,
      friend2,
      friend3,
      sponsor,
      sponsor2,
      vendor1,
      vendor2,
      vendor3,
    ] = await ethers.getSigners();

    const TokenContract = await ethers.getContractFactory("MyToken", {
      signer: owner,
    });

    const token = await upgrades.deployProxy(
      TokenContract,
      ["My Token", "MT"],
      {
        kind: "uups",
        initializer: "initialize",
      }
    );

    const EntryPointContract = await ethers.getContractFactory(
      EntryPointArtifact.abi,
      EntryPointArtifact.bytecode,
      owner
    );
    const entrypointDeployment = await EntryPointContract.deploy();

    const entrypoint = await entrypointDeployment.waitForDeployment();

    const CardManagerContract = await ethers.getContractFactory("CardManager", {
      signer: owner,
    });

    const cardManager = await CardManagerContract.deploy(
      await entrypoint.getAddress(),
      await entrypoint.getAddress(), // just to satisfy the constructor, we don't need this
      [vendor1.address, vendor2.address]
    );

    return {
      owner,
      token,
      friend1,
      friend2,
      friend3,
      sponsor,
      sponsor2,
      vendor1,
      vendor2,
      vendor3,
      cardManager,
    };
  }

  describe("Hash", function () {
    it("Should generate a stable hash from serial number", async function () {
      const { cardManager } = await loadFixture(deployCardManagerFixture);

      const serial = 123;

      const hash = await cardManager.getCardHash(serial);
      const hash2 = await cardManager.getCardHash(serial);

      expect(hash).to.equal(hash2);
    });
  });

  describe("Create Card", function () {
    async function deployCardFixture() {
      const { cardManager, friend1 } = await loadFixture(
        deployCardManagerFixture
      );

      const serial = 123;

      const hash = await cardManager.getCardHash(serial);

      const tx = await cardManager.createCard(hash);

      await tx.wait();

      const cardAddress = await cardManager.getCardAddress(hash);

      const card = await ethers.getContractAt("Card", cardAddress);

      return {
        cardManager,
        serial,
        hash,
        card,
        friend1,
      };
    }

    it("Should generate a card from serial number", async function () {
      const { cardManager } = await loadFixture(deployCardFixture);

      const serial = Math.floor(Math.random() * 1000000);

      const hash = await cardManager.getCardHash(serial);

      const tx = await cardManager.createCard(hash);

      await tx.wait();

      const cardAddress = await cardManager.getCardAddress(hash);

      const card = await ethers.getContractAt("Card", cardAddress);

      expect(await card.getAddress()).to.equal(cardAddress);
    });

    it("Should return the same card address from serial number", async function () {
      const { cardManager, serial, card } = await loadFixture(
        deployCardFixture
      );

      const hash = await cardManager.getCardHash(serial);

      const cardAddress = await cardManager.getCardAddress(hash);

      expect(await card.getAddress()).to.equal(cardAddress);
    });

    it("Should set owner of the card to card manager", async function () {
      const { cardManager, card } = await loadFixture(deployCardFixture);

      expect(await card.owner()).to.equal(await cardManager.getAddress());
    });

    it("Should be able to transfer ownership", async function () {
      const { cardManager, hash, card, friend1 } = await loadFixture(
        deployCardFixture
      );

      expect(await card.owner()).to.not.equal(friend1.address);

      await cardManager.transferCardOwnership(hash, friend1.address);

      expect(await card.owner()).to.equal(friend1.address);

      await expect(cardManager.transferCardOwnership(hash, friend1.address)).to
        .be.reverted;
    });
  });

  describe("Whitelist", function () {
    it("Should have vendors on the whitelist", async function () {
      const { cardManager, vendor1, vendor2 } = await loadFixture(
        deployCardManagerFixture
      );

      expect(await cardManager.isWhitelisted(vendor1.address)).to.be.true;
      expect(await cardManager.isWhitelisted(vendor2.address)).to.be.true;
    });

    it("Should have not have some vendors on the whitelist", async function () {
      const { cardManager, vendor3 } = await loadFixture(
        deployCardManagerFixture
      );

      expect(await cardManager.isWhitelisted(vendor3.address)).to.be.false;
    });

    it("Should be able to update the whitelist", async function () {
      const { cardManager, vendor1, vendor3 } = await loadFixture(
        deployCardManagerFixture
      );

      await cardManager.updateWhitelist([vendor3.address]);

      expect(await cardManager.isWhitelisted(vendor1.address)).to.be.false;
      expect(await cardManager.isWhitelisted(vendor3.address)).to.be.true;
    });
  });

  describe("Card", function () {
    async function deployCardFixture() {
      const { owner, token, cardManager, vendor1, vendor3 } = await loadFixture(
        deployCardManagerFixture
      );

      const serial = 123;

      const hash = await cardManager.getCardHash(serial);

      const tx = await cardManager.createCard(hash);

      await tx.wait();

      const cardAddress = await cardManager.getCardAddress(hash);

      const card = await ethers.getContractAt("Card", cardAddress);

      return {
        owner,
        token,
        cardManager,
        serial,
        hash,
        card,
        vendor1,
        vendor3,
      };
    }

    it("Should be able to hold a token", async function () {
      const { token, card } = await loadFixture(deployCardFixture);

      const mintAmount = 100;

      await token.mint(await card.getAddress(), mintAmount);

      expect(await token.balanceOf(await card.getAddress())).to.equal(
        mintAmount
      );
    });

    it("Whitelisted Vendors should be able to withdraw tokens", async function () {
      const { token, card, vendor1 } = await loadFixture(deployCardFixture);

      const mintAmount = 100;

      await token.mint(await card.getAddress(), mintAmount);

      await card.connect(vendor1).withdraw(await token.getAddress(), 10);

      expect(await token.balanceOf(vendor1.address)).to.equal(10);
    });

    it("Vendors who are not whitelisted should not be able to withdraw tokens", async function () {
      const { token, card, vendor3 } = await loadFixture(deployCardFixture);

      const mintAmount = 100;

      await token.mint(await card.getAddress(), mintAmount);

      await expect(card.connect(vendor3).withdraw(await token.getAddress(), 10))
        .to.be.reverted;

      expect(await token.balanceOf(vendor3.address)).to.equal(0);
    });

    it("Whitelisted Vendors should be able to withdraw tokens using card manager", async function () {
      const { token, cardManager, hash, card, vendor1 } = await loadFixture(
        deployCardFixture
      );

      const mintAmount = 100;

      await token.mint(await card.getAddress(), mintAmount);

      await cardManager
        .connect(vendor1)
        .withdraw(hash, await token.getAddress(), vendor1.address, 10);

      expect(await token.balanceOf(vendor1.address)).to.equal(10);
    });

    it("Vendors who are not whitelisted should not be able to withdraw tokens using card manager", async function () {
      const { cardManager, token, hash, card, vendor3 } = await loadFixture(
        deployCardFixture
      );

      const mintAmount = 100;

      await token.mint(await card.getAddress(), mintAmount);

      await expect(
        cardManager
          .connect(vendor3)
          .withdraw(hash, await token.getAddress(), vendor3.address, 10)
      ).to.be.reverted;

      expect(await token.balanceOf(vendor3.address)).to.equal(0);
    });
  });
});
