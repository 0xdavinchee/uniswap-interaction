import { expect } from "./chai-setup";
import { Greeter } from "../typechain";
import { ethers, deployments } from "hardhat";

const setup = async () => {
  await deployments.fixture(["Greeter"]);
  const contracts = {
    Greeter: await ethers.getContract("Greeter") as Greeter,
  };

  return { ...contracts };
};

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const { Greeter } = await setup();
    expect(await Greeter.greet()).to.equal("Hello Hardhat!");

    await Greeter.setGreeting("Hola, mundo!");
    expect(await Greeter.greet()).to.equal("Hola, mundo!");
  });
});
