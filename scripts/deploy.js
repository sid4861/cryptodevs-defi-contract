const hre = require("hardhat");
const { CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS } = require("../constants");

async function main() {
    const exchangeContractFactory = await hre.ethers.getContractFactory("Exchange");
    const exchangeContract = await exchangeContractFactory.deploy(CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS);
    await exchangeContract.deployed();

    console.log(exchangeContract.address);


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });