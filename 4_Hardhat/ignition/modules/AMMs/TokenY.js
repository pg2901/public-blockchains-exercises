const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")
require('dotenv').config()

module.exports = buildModule("TokenYModule", (m) => {
  const name = "TokenY"
  const symbol = "TY"

  const con = m.contract('TokenTemplate', [name, symbol])

  return { con }
})