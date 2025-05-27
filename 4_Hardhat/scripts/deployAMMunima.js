require("dotenv").config();
// const { ethers } = require("ethers");
const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.NOT_UNIMA_URL_1);
  const signer = new ethers.Wallet(process.env.METAMASK_1_PRIVATE_KEY, provider);

  console.log("Signer used:", signer.address)

  const addresses = require('../ignition/deployments/chain-585858/deployed_addresses.json')
  const validatorAddress = "0xc5a6FaC374B99119d5D3d088C80c007b5Ff9f059"

  const ammXaddress = addresses["AMMXModule#AMM"]
  const ammYaddress = addresses["AMMYModule#AMM"]
  const ammContractName = "AMM"
  const ammAbi = JSON.parse(fs.readFileSync(`./artifacts/contracts/5_AMM/${ammContractName}.sol/${ammContractName}.json`)).abi
  const ammX = new ethers.Contract(ammXaddress, ammAbi, signer)
  const ammY = new ethers.Contract(ammYaddress, ammAbi, signer)

  const registryAddress = "0xa269147eD50Eb19038d88981Fbe408ac39954FBA"
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
  // Call both token's Approve function from signer for validator
  // Register AMMX and AMMY at AMMRegistry

  const waitForTx = async function (tx, verbose = 0) {
    console.log("Transaction in mempool...")
    const receipt = await tx.wait()
    if (verbose) {
      console.log(receipt)
    }
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

  await registerAMMs()

  const approveAMMs = async function () {
    console.log("Approve AMMX for signer:", signer.address)

    let balance = await tokenX.balanceOf(signer.address)
    console.log("Balance of signer:", ethers.formatEther(balance))

    const approvalAmount = ethers.parseEther("500")
    console.log("Approve AMMX use for:", ethers.formatEther(approvalAmount))
    let tx = await tokenX.approve(ammXaddress, approvalAmount)
    await waitForTx(tx)

    console.log("Approve AMMY for signer:", signer.address)
    console.log("Approve AMMY use for:", ethers.formatEther(approvalAmount))
    tx = await tokenY.approve(ammYaddress, approvalAmount)
    await waitForTx(tx)

    console.log("Approve Validator for Token X")
    tx = await tokenX.approve(validatorAddress, approvalAmount)
    await waitForTx(tx, 1)

    console.log("Approve Validator for Token Y")
    tx = await tokenY.approve(validatorAddress, approvalAmount)
    await waitForTx(tx, 1)
  }

  // await approveAMMs();

  const provideLiquidity = async function () {
    const balance = await tokenX.balanceOf(signer)
    console.log("Balance of signer:", ethers.formatEther(balance))

    const liquidityProvided = ethers.parseEther("2")

    console.log(`-- Sending ${ethers.formatEther(liquidityProvided)} tokens and ETH to AMMX --`)
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

  // await provideLiquidity()

  const removeLiquidity = async function () {
    const lpBalance = await ammX.balanceOf(signer)

    console.log(`-- Removing ${ethers.formatEther(lpBalance/2n)} LP tokens worth of liquidity --`)
    console.log(`Current LP Token Balance of signer: ${ethers.formatEther(lpBalance)}`)
    console.log(`Current Token Pool of AMMX: ${ethers.formatEther(await ammX.getTokenPool())}`)
    console.log(`Current ETH Pool of AMMX: ${ethers.formatEther(await ammX.getETHPool())}`)
    let tx = await ammX.removeLiquidity(lpBalance/2n)
    await waitForTx(tx)

    console.log(`New LP Balance of Signer: ${ethers.formatEther(await ammX.balanceOf(signer))}`)
    console.log(`New Token Pool of AMMX: ${ethers.formatEther(await ammX.getTokenPool())}`)
    console.log(`New ETH Pool of AMMX: ${ethers.formatEther(await ammX.getETHPool())}`)
  }

  // await removeLiquidity()

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