import { HardhatUserConfig, task } from "hardhat/config";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-prettier";
import "hardhat-typechain";
import "solidity-coverage";
import { Swapper } from "./typechain";

const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC_ADDRESS = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

task("swapper", "test the functions", async (_args, hre) => {
  const contract = await hre.ethers.getContractFactory("Swapper");
  const swapper = (await contract.attach(
    "0x9E545E3C0baAB3E08CdfD552C960A1050f373042"
  )) as Swapper;
  const result = await swapper.getBestInput(
    hre.ethers.utils.parseUnits("2500"),
    [WETH_ADDRESS, USDC_ADDRESS]
  );
  console.log(result);
  const receipt = await result.wait();
});

const config: HardhatUserConfig = {
  solidity: "0.6.6",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/87d4e8453b7f432f8f973ec0e50efa21",
      accounts: [
        "ecdd79c908e3bcd1387a6f0ccac319ce919f35bf116416123ba815a2b6fe0e08",
      ],
    },
    // hardhat: {
    //   forking: {
    //     url: "https://eth-mainnet.alchemyapi.io/v2/dBvUq7mS2ls7ATR2Uux2Ld1NwsVoxo3l",
    //     blockNumber: 12592080,
    //   },
    // },
  },
  namedAccounts: {
    deployer: 0,
  },
};

export default config;
