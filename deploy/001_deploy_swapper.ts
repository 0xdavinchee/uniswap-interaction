import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("Swapper", {
    from: deployer,
    args: [
      "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
      "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac", // mainnet
      // "0xc35DADB65012eC5796536bD9864eD8773aBc74C4", rinkeby
      "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", // mainnet
      // "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506", rinkeby
    ],
    log: true,
  });
};

export default func;
func.tags = ["Swapper"];
