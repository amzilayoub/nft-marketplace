require("@nomicfoundation/hardhat-toolbox")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL
const SEPOLIA_CHAIN_ID = process.env.SEPOLIA_CHAIN_ID
const PRIVATE_KEY = process.env.PRIVATE_KEY
const COINMARKER_API_KEY = process.env.COINMARKER_API_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

module.exports = {
	defaultNetwork: "hardhat",
	networks: {
		hardhat: {
			chainId: 31337,
			blockConfirmations: 1,
		},
		sepolia: {
			chainId: parseInt(SEPOLIA_CHAIN_ID),
			blockConfirmations: 1,
			url: SEPOLIA_RPC_URL,
			accounts: [PRIVATE_KEY],
		},
	},
	gasReporter: {
		enabled: false,
	},
	solidity: "0.8.7",
	namedAccounts: {
		deployer: {
			default: 0,
		},
		player: {
			default: 1,
		},
	},
	mocha: {
		timeout: 200000, // 200 seconds
	},
	etherscan: {
		apiKey: ETHERSCAN_API_KEY,
	},
}
