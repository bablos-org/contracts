require('dotenv').config();
const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  networks: {
    development: {
        host: "localhost",
        port: 8545,
        network_id: "*", // Match any network id
        gas: 3271168
    },
    ropsten: {
      provider: new HDWalletProvider(process.env.MNENOMIC, "https://ropsten.infura.io/" + process.env.INFURA_API_KEY),
      network_id: 3,
      gas: 3271168
    },
    rinkeby: {
      provider: new HDWalletProvider(process.env.MNENOMIC, "https://rinkeby.infura.io/" + process.env.INFURA_API_KEY),
      network_id: 4,
      gas: 3271168
    },
    mainnet: {
      provider: new HDWalletProvider(process.env.MNENOMIC, "https://mainnet.infura.io/" + process.env.INFURA_API_KEY),
      network_id: 1,
      gas: 3271168,
      gasPrice: 2800000000
    },
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
