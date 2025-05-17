const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")
require('dotenv').config()

module.exports = buildModule("AMMRegistryModule", (m) => {

  const con = m.contract('AMMRegistry')

  return { con }
})