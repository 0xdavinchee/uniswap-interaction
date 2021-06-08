import { expect } from "./chai-setup";
import { Swapper } from "../typechain";
import { ethers, deployments } from "hardhat";

const setup = async () => {
  await deployments.fixture(["Swapper"]);
  const contracts = {
    Swapper: (await ethers.getContract("Swapper")) as Swapper,
  };

  return { ...contracts };
};

const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const LINK_ADDRESS = "0x514910771af9ca656af840dff83e8264ecf986ca";

describe("Swapper", function () {
  it("Should return the new greeting once it's changed", async function () {
    const { Swapper } = await setup();
  });
});
