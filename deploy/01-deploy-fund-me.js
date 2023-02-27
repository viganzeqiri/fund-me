const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const { chainId } = network.config;

  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: [],
    log: true,
  });
};
