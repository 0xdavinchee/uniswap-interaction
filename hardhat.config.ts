import { HardhatUserConfig } from "hardhat/config";
import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-prettier";
import "hardhat-typechain";
import "solidity-coverage";

const config: HardhatUserConfig = {
  solidity: "0.6.6",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
    },
    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: [process.env.RINKEBY_PRIVATE_KEY || ""],
    },
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_MAINNET_URL || "",
      },
    },
  },
  namedAccounts: {
    deployer: 0,
  },
};

export default config;
