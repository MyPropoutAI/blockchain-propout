require("@matterlabs/hardhat-zksync-solc");

/** @type import('hardhat/config').HardhatUserConfig */

const RPC_URL_TEST = "https://rpc.fusespark.io/";
const RPC_URL = "https://rpc.fusespark.io/";
module.exports = {
  zksolc: {
    version: "1.3.9",
    compilerSource: "binary",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  defaultNetwork: "lisk-sepolia",
  networks: {
    fuse: {
      url: RPC_URL,
      accounts: [
        "0xb79ccd1b062531869010ac01ed261c26e67f6ef623072818b57c0f25cfe63ffa",
      ],
    },
    fuseSparknet: {
      url: RPC_URL_TEST,
      accounts: [
        "0xf60f6718573e07f07c581e34922294749fd2f32ac9b45018af8414031a951856",
      ],
    },
    "lisk-sepolia": {
      url: "https://rpc.sepolia-api.lisk.com",
      accounts: [
        "0xf60f6718573e07f07c581e34922294749fd2f32ac9b45018af8414031a951856",
      ],
      gasPrice: 1000000000,
    },
  },
  paths: {
    artifacts: "./artifacts-zk",
    cache: "./cache-zk",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
