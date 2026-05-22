const hre = require("hardhat");

async function main() {
  console.log("Starting deployment of TouristIdentity contract...");

  // Get contract factory
  const TouristIdentity = await hre.ethers.getContractFactory("TouristIdentity");
  
  // Deploy the contract
  const contract = await TouristIdentity.deploy();

  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();

  console.log("====================================================");
  console.log(`TouristIdentity contract successfully deployed!`);
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Transaction Hash: ${contract.deploymentTransaction().hash}`);
  console.log("====================================================");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
