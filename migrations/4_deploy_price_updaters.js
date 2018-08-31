const PriceUpdater = artifacts.require('./oracles/PriceUpdater.sol');

const priceUpdateInterval = 60 * 60 * 2; // 2 hour
const maxInterval = 60 * 60 * 2; // 2 hour

module.exports = function (deployer, network, accounts) {
  return deployer
    .then(() => {
      return deployer.deploy(
        PriceUpdater,
        priceUpdateInterval,
        maxInterval);
    }).then(() => {
      return PriceUpdater.deployed().then((updater) => {
        updater.setPricesManually('237.408;0.17;79.221;1.169');
        updater.updatePrice({value: 0.5 * 10**18});
      });
    });
};