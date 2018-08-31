const BablosToken = artifacts.require('./tokens/BablosToken.sol');
const BablosDividend = artifacts.require('./dividends/BablosDividend.sol');

module.exports = function (deployer, network, accounts) {
  return deployer
    .then(() => {
      return deployer.deploy(
        BablosDividend,
        BablosToken.address);
    }).then(() => {
      return BablosToken.deployed().then(function (token) {
        token.setDividends(BablosDividend.address);
      });
    });
};