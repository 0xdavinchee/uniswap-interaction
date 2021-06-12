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
      "0xc35DADB65012eC5796536bD9864eD8773aBc74C4",
      "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
      "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506",
    ],
    log: true,
  });
};

export default func;
func.tags = ["Swapper"];
