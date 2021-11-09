require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("hardhat-contract-sizer");

// Upgradeable contract.
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');

const { MNEMONIC, PRIVATE_KEY } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    tomotestnet: {
      url: "https://testnet.tomochain.com",
      // accounts: {
      //   mnemonic: MNEMONIC?? "",
      //   initialIndex: 0,
      //   count: 1,
      //   path: "m/44'/60'/0'/0",
      // },
      accounts: [
        PRIVATE_KEY ||
          "0xaa30e816d1dfb91e70b259711f39a63b310a0e10a47e11b0e1f900c7e20a7ab7",
      ],
    },
    tomomainnet: {
      url: "https://rpc.tomochain.com",
      // accounts: {
      //   mnemonic: MNEMONIC?? "",
      //   initialIndex: 0,
      //   count: 1,
      //   path: "m/44'/60'/0'/0",
      // },
      accounts: [
        PRIVATE_KEY ||
          "0xaa30e816d1dfb91e70b259711f39a63b310a0e10a47e11b0e1f900c7e20a7ab7",
      ],
    },
    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${INFURA_KEY}`,
    //   accounts: {
    //     mnemonic: MNEMONIC,
    //   },
    // },
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: false,
    disambiguatePaths: false,
  },
};
