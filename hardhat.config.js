require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-truffle5");

const { mnemonic, apiKey } = require('./secrets.json');

module.exports = {
	solidity: {
		version: "0.8.4",
		settings: {
			optimizer: {
				enabled: true,
				runs: 10
			}
		}
	},
	networks: {
		testnet: {
			url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
			gas: 10000000,
			accounts: { mnemonic: mnemonic }
		},
		main: {
			url: "https://bsc-dataseed.binance.org/",
			gas: 10000000,
			accounts: { mnemonic: mnemonic }
		}
	},
	etherscan: {
		apiKey: apiKey
	}
};
