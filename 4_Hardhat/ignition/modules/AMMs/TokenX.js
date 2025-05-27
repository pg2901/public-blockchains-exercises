const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")
require('dotenv').config()
const hre = require('hardhat')

module.exports = buildModule("TokenXModule", (m) => {
  const name = "TokenX"
  const symbol = "TX"
  const initialSupply = hre.ethers.parseEther("2000")

  const con = m.contract('TokenTemplate', [name, symbol, initialSupply])

  return { con }
})