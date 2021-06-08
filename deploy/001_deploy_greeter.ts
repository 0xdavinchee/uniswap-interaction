import { HardhatRuntimeEnvironment } from "hardhat/types";
import {DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("Greeter", {
    from: deployer,
    args: ["Hello Hardhat!"],
    log: true
  });
}

export default func;
func.tags = ["Greeter"];