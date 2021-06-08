import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("Swapper", {
    from: deployer,
    args: ["0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"],
    log: true,
  });
};

export default func;
func.tags = ["Swapper"];
