const hre = require("hardhat");

async function main() {
  const GameItem = await hre.ethers.getContractFactory("GameItem");
  const gameItem = await GameItem.deploy(
    3014,
    "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
  );
  await gameItem.deployed();
  console.log("GameItem deployed to:", gameItem.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
