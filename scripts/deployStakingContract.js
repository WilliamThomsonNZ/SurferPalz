const {
  NFT_CONTRACT_ADDRESS,
  TOKEN_CONTRACT_ADDRESS,
} = require("../constants");
const hre = require("hardhat");

async function main() {
  const StakingContract = await hre.ethers.getContractFactory("ItemStake");
  const stakingContract = await StakingContract.deploy(
    TOKEN_CONTRACT_ADDRESS,
    NFT_CONTRACT_ADDRESS
  );
  await stakingContract.deployed();
  console.log("GameToken deployed to:", stakingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
