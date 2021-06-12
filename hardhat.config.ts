import { HardhatUserConfig } from "hardhat/config";
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
      url: "https://rinkeby.infura.io/v3/87d4e8453b7f432f8f973ec0e50efa21",
      accounts: [""],
    },
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/dBvUq7mS2ls7ATR2Uux2Ld1NwsVoxo3l",
      },
    },
  },
  namedAccounts: {
    deployer: 0,
  },
};

export default config;
