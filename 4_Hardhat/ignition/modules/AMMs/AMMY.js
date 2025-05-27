const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")
require('dotenv').config()
const addresses = require("../../deployments/chain-31337/deployed_addresses.json")
const unimaAddresses = require("../../deployments/chain-585858/deployed_addresses.json")

module.exports = buildModule("AMMYModule", (m) => {
  const name = "AMMY"
  const symbol = "AY"
  const tokenAddressLocal = addresses["TokenYModule#TokenTemplate"]
  const tokenAddress = unimaAddresses["TokenYModule#TokenTemplate"]
  const validatorLocal = addresses["ValidatorModule#EmptyValidator"]
  const validator = "0xc5a6FaC374B99119d5D3d088C80c007b5Ff9f059"
  const registryLocal = addresses["AMMRegistryModule#AMMRegistry"]
  const registry = "0xa269147eD50Eb19038d88981Fbe408ac39954FBA"

  const con = m.contract('AMM', [name, symbol, tokenAddress, registry, validator])

  return { con }
})