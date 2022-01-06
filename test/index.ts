import { expect, use } from "chai";
import { providers } from "ethers";
import { ethers, waffle } from "hardhat";
import { env } from "process";

import {
  PhudgyPhenguins,
  PudgyPenguins,
  PudgyPenguinsCopy,
} from "../typechain";

// Only depend on ownerOf so just including that method
const pudgyAbi = [
  {
    constant: true,
    inputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
    name: "ownerOf",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    payable: false,
    stateMutability: "view",
    type: "function",
  },
];

describe("PhudgyPhenguins", function () {
  const [wallet1, wallet2] = waffle.provider.getWallets();
  let phudgyContract: PhudgyPhenguins;
  let pudgyContract: PudgyPenguinsCopy;

  beforeEach(async () => {
    const PudgyContract = await ethers.getContractFactory("PudgyPenguinsCopy");
    pudgyContract = await PudgyContract.deploy("baseuri");
    await pudgyContract.deployed();

    const PhudgyContract = await ethers.getContractFactory("PhudgyPhenguins");
    phudgyContract = await PhudgyContract.deploy(
      pudgyContract.address,
      "baseuri"
    );
    await phudgyContract.deployed();
  });

  it("Should emit event with tokenId on public mint", async function () {
    await phudgyContract.setPublicMinting(true);
    expect(
      await phudgyContract.publicMint(1, {
        value: ethers.utils.parseEther(".0169"),
      })
    )
      .to.emit(phudgyContract, "CreatePhenguin")
      .withArgs(0);
  });

  it("Should support pudgy mints and public mints that skip used ids", async function () {
    await pudgyContract.mint(wallet2.address, 3);

    expect(await phudgyContract.connect(wallet2).pudgyMint(1))
      .to.emit(phudgyContract, "CreatePhenguin")
      .withArgs(1);

    expect(await phudgyContract.totalSupply()).to.equal(1);
    await phudgyContract.setPublicMinting(true);

    await phudgyContract.publicMint(2, {
      value: ethers.utils.parseEther(".0338"),
    });

    expect(await phudgyContract.totalSupply()).to.be.equal(3);
    expect(await phudgyContract.ownerOf(1)).to.be.equal(wallet2.address);
    // wallet 1 got 2 nfts
    expect(await phudgyContract.balanceOf(wallet1.address)).to.equal(2);
    // wallet 1 got the right nfts
    expect(await phudgyContract.ownerOf(0)).to.be.equal(wallet1.address);
    expect(await phudgyContract.ownerOf(2)).to.be.equal(wallet1.address);
  });

  it("Should reject pudgy minting an id it doesnt own", async function () {
    await pudgyContract.connect(wallet2).mint(wallet2.address, 1);
    await expect(phudgyContract.connect(wallet1).pudgyMint(0)).to.be.reverted;
  });
});
