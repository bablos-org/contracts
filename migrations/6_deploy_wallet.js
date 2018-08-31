const BablosToken = artifacts.require('./tokens/BablosToken.sol');
const BablosCrowdsale = artifacts.require('./crowdsales/BablosCrowdsale.sol');
const BablosCrowdsaleWallet = artifacts.require('./wallets/BablosCrowdsaleWallet.sol');
const PriceUpdater = artifacts.require('./oracles/PriceUpdater.sol');

const admin = '0xc29466f1f6534e22171544f0d6188bcaf57a6cfa';
const totalSupply = 2 * 10**6;
const teamPercent = 15;
const prAmount = 17000;
const teamAmount = totalSupply * 15 / 100 - prAmount;
const saleAmount = totalSupply * 85 / 100;

module.exports = function (deployer, network, accounts) {
  return deployer
    .then(() => {
      return deployer.deploy(
        BablosCrowdsaleWallet,
        BablosToken.address,
        BablosCrowdsale.address,
        PriceUpdater.address,
        teamPercent,
        prAmount);
    }).then(() => {
      return BablosCrowdsale.deployed().then(function (crowdsale) {
        crowdsale.setWallet(BablosCrowdsaleWallet.address);
      });
    }).then(() => {
      return BablosToken.deployed().then(function(token) {
        token.transfer(admin, prAmount);
        token.transfer(BablosCrowdsaleWallet.address, teamAmount);
        token.transfer(BablosCrowdsale.address, saleAmount);
      });
    }).then(() => {
      return BablosToken.deployed().then(function (token) {
        token.setSale(BablosCrowdsale.address);
      });
    }).then(() => {
      return BablosCrowdsaleWallet.deployed().then(function(wallet) {
        wallet.transferOwnership(admin);
      });
    });
};