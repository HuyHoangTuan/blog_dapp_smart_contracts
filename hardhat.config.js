require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  settings: {
    optimizer: {
      enabled: true,
      runs: 1,
    },
    viaIR: true,
  },
  networks: {
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/0drTashIXwsB5eKpvK72nHrfdQf_nHbK",
      accounts: [
        "9b86b025262df65a3146732b9b592b0a65fb7da9e12b5fb62dd3ae188804ed0c"
      ]
    }
  }
};
