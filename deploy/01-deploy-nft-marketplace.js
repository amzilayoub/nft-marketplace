const {network, ethers} = require('hardhat')
const {developmentChains} = require('../helper-hardhat-config')
const {verify} = require('../utils/verify')
require('dotenv').config()

module.exports = async function ({getNamedAccounts, deployments}) {
    const {deployer} = (await getNamedAccounts())
    const {deploy, log} = deployments

    // set different config depending on thenetwork
    // but since the constructor doesn't take any parameter
    // we can ignore this part
    //
    // Deploy
    const args = []
    log(`Deploying the NftMarketplace contract on: ${network.name}`)
    const nftMarketPlaceContract = await deploy('NftMarketplace', {
        from: deployer,
        args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY)
    {
        log("Verifying...")
        await verify(nftMarketPlaceContract.address, args)
        log('Verification done')
    }
    log('------------------------')
}

module.exports.tags = ['all', 'nftmarketplace']