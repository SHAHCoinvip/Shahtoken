// scripts/deploy-router.js
require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying ShahSwap...");

  const shahTokenAddress = process.env.SHAH_TOKEN_ADDRESS;

  if (!shahTokenAddress || !ethers.utils.isAddress(shahTokenAddress)) {
    throw new Error(`❌ Invalid SHAH token address in .env: ${shahTokenAddress}`);
  }

  const ShahSwap = await ethers.getContractFactory("ShahSwap");
  const shahSwap = await ShahSwap.deploy(shahTokenAddress);

  await shahSwap.deployed();
  console.log("✅ ShahSwap deployed at:", shahSwap.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment error:", error);
    process.exit(1);
  });
