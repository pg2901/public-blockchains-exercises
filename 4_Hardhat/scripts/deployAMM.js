require("dotenv").config();
// const { ethers } = require("ethers");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");

async function main() {
  // const provider = new ethers.JsonRpcProvider(process.env.NOT_UNIMA_URL_1);
  // const signer = new ethers.Wallet(process.env.METAMASK_1_PRIVATE_KEY, provider);

  const [signer] = await ethers.getSigners()
  console.log("Signer used:", signer.address)
  // const validatorName = "EmptyValidator"
  //const contractArtifact = JSON.parse(fs.readFileSync(`../artifacts/contracts/${EmptyValidator}.sol/${EmptyValidator}.json`))
  const addresses = require('../ignition/deployments/chain-31337/deployed_addresses.json')
  // const addresses = require('../ignition/deployments/chain-585858/deployed_addresses.json')
  // const validatorAddress = addresses["ValidatorModule#EmptyValidator"]

  const ammXaddress = addresses["AMMXModule#AMM"]
  const ammYaddress = addresses["AMMYModule#AMM"]
  const ammContractName = "AMM"
  const ammAbi = JSON.parse(fs.readFileSync(`./artifacts/contracts/5_AMM/${ammContractName}.sol/${ammContractName}.json`)).abi
  const ammX = new ethers.Contract(ammXaddress, ammAbi, signer)
  const ammY = new ethers.Contract(ammYaddress, ammAbi, signer)

  const registryAddress = addresses["AMMRegistryModule#AMMRegistry"]
  // const registryAddress = "0xa269147eD50Eb19038d88981Fbe408ac39954FBA"
  const registryContractName = "AMMRegistry"
  const registryAbi = JSON.parse(fs.readFileSync(`./artifacts/contracts/5_AMM/${registryContractName}.sol/${registryContractName}.json`)).abi
  const registry = new ethers.Contract(registryAddress, registryAbi, signer)

  const tokenXaddress = addresses["TokenXModule#TokenTemplate"]
  const tokenYaddress = addresses["TokenYModule#TokenTemplate"]

  const tokenContractName = "TokenTemplate"
  const tokenAbi = JSON.parse(fs.readFileSync(`./artifacts/contracts/5_AMM/${tokenContractName}.sol/${tokenContractName}.json`)).abi
  const tokenX = new ethers.Contract(tokenXaddress, tokenAbi, signer)
  const tokenY = new ethers.Contract(tokenYaddress, tokenAbi, signer)
  // Things to do
  // Call Token X's Approve function from signer for AMMX
  // Call Token Y's Approve function from signer for AMMY
  // Register AMMX and AMMY at AMMRegistry

  const waitForTx = async function (tx) {
    console.log("Transaction in mempool...")
    await tx.wait()
    console.log("Transaction mined")
  }

  const registerAMMs = async function () {
    console.log("-- Register AMM X --")
    let tx = await registry.registerAMM(ammXaddress)
    await waitForTx(tx)

    console.log("-- Register AMM Y --")
    tx = await registry.registerAMM(ammYaddress)
    await waitForTx(tx)
  }

  // await registerAMMs()

  const approveAMMs = async function () {
    console.log("Approve AMMX for signer:", signer.address)

    let balance = await tokenX.balanceOf(signer.address)
    console.log("Balance of signer:", ethers.formatEther(balance))

    const approvalAmount = balance/2n
    console.log("Approve AMMX use for:", ethers.formatEther(approvalAmount))
    let tx = await tokenX.approve(ammXaddress, approvalAmount)
    await waitForTx(tx)

    console.log("Approve AMMY for signer:", signer.address)
    console.log("Approve AMMY use for:", ethers.formatEther(approvalAmount))
    tx = await tokenY.approve(ammYaddress, approvalAmount)
    await waitForTx(tx)
  }

  // await approveAMMs();

  const provideLiquidity = async function () {
    const balance = await tokenX.balanceOf(signer)
    console.log("Balance of signer:", ethers.formatEther(balance))

    const liquidityProvided = balance/4n

    console.log(`-- Sending ${ethers.formatEther(liquidityProvided)} tokens and ETH to AMMX`)
    console.log(`Current Token Pool of AMMX: ${ethers.formatEther(await ammX.getTokenPool())}`)
    console.log(`Current ETH Pool of AMMX: ${ethers.formatEther(await ammX.getETHPool())}`)
    let tx = await ammX.addLiquidity(liquidityProvided, {
      value: liquidityProvided
    })
    await waitForTx(tx)

    console.log(`New Token Pool of AMMX: ${ethers.formatEther(await ammX.getTokenPool())}`)
    console.log(`New ETH Pool of AMMX: ${ethers.formatEther(await ammX.getETHPool())}`)

    console.log(`-- Sending ${ethers.formatEther(liquidityProvided)} tokens and ETH to AMMY`)
    console.log(`Current Token Pool of AMMY: ${ethers.formatEther(await ammY.getTokenPool())}`)
    console.log(`Current ETH Pool of AMMY: ${ethers.formatEther(await ammY.getETHPool())}`)
    tx = await ammY.addLiquidity(liquidityProvided, {
      value: liquidityProvided
    })
    await waitForTx(tx)

    console.log(`New Token Pool of AMMY: ${ethers.formatEther(await ammY.getTokenPool())}`)
    console.log(`New ETH Pool of AMMY: ${ethers.formatEther(await ammY.getETHPool())}`)
  }

  await provideLiquidity()

  const testTransfer = async function () {
    console.log("How many X tokens would you get for 5 ETH?")
    let tokens = await ammX.getTokenAmount(ethers.parseEther("5"))
    console.log(ethers.formatEther(tokens), "Tokens")

    console.log("How many Y tokens would you get for 5 ETH?")
    tokens = await ammY.getTokenAmount(ethers.parseEther("5"))
    console.log(ethers.formatEther(tokens), "Tokens")

    console.log("How many ETH would you get for 5 X tokens?")
    let eth = await ammX.getETHAmount(ethers.parseEther("5"))
    console.log(ethers.formatEther(eth), "ETH")

    console.log("How many ETH would you get for 5 Y tokens?")
    eth = await ammY.getETHAmount(ethers.parseEther("5"))
    console.log(ethers.formatEther(eth), "ETH")
  }

  // await testTransfer()
}

main()