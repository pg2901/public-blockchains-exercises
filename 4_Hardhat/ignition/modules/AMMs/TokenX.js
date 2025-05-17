const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")
require('dotenv').config()

module.exports = buildModule("TokenXModule", (m) => {
  const name = "TokenX"
  const symbol = "TX"

  const con = m.contract('TokenTemplate', [name, symbol])

  return { con }
})