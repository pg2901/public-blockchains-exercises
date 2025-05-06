const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")

module.exports = buildModule("GasTestModule", (m) => {
  const contract = m.contract("GasTest")
  return { contract }
})