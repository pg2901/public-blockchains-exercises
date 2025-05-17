require("dotenv").config();
const { ethers } = require("ethers");
const fs = require("fs");

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.NOT_UNIMA_URL_1);
  const signer = new ethers.Wallet(process.env.METAMASK_1_PRIVATE_KEY, provider);

  const validatorName = "EmptyValidator"
  const contractArtifact = JSON.parse(fs.readFileSync(`../artifacts/contracts/${EmptyValidator}.sol/${EmptyValidator}.json`))
}