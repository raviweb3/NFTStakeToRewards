// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const StakeRewards = await hre.ethers.getContractFactory("StakeRewards");
  const stakeRewards = await StakeRewards.deploy();

  await stakeRewards.deployed();

  console.log(
    `Deployed Stake Rewards  deployed to ${stakeRewards.address}`
  );

  const NFTCollection = await hre.ethers.getContractFactory("NFTCollection");
  const nftCollection = await NFTCollection.deploy();

  await nftCollection.deployed();

  console.log(
    `Deployed NFTCollection  deployed to ${nftCollection.address}`
  );


  const NFTStaking = await hre.ethers.getContractFactory("NFTStaking");
  const nftStaking = await NFTStaking.deploy(nftCollection.address, stakeRewards.address);

  await nftStaking.deployed();

  console.log(
    `Deployed NFTStaking  deployed to ${nftStaking.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
