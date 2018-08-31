const BablosToken = artifacts.require('./tokens/BablosToken.sol');
const InvestorDividend = artifacts.require('./dividends/InvestorDividend.sol');

const admin = '0xc29466f1f6534e22171544f0d6188bcaf57a6cfa';
const publicKey = '8750658c4a0d2665297202fc0ddbfb5db4f61ec7bebc8b6849ec30d309739756632c81cfb897cd05f3347685ba9';
const minimumAmount = 20000;

module.exports = function (deployer, network, accounts) {
  return deployer
    .then(() => {
      return deployer.deploy(
        InvestorDividend,
        BablosToken.address,
        minimumAmount);
    }).then(() => {
      return InvestorDividend.deployed().then(function (dividend) {
        dividend.setPublicKey(publicKey);
        dividend.transferOwnership(admin);
      });
    });
};