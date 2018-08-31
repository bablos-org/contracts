const MerchantController = artifacts.require('./merchant/MerchantController.sol');
const BablosCrowdsale = artifacts.require('./crowdsales/BablosCrowdsale.sol');
const PriceUpdater = artifacts.require('./oracles/PriceUpdater.sol');

const merchantAddress = '0xa04c1b01dee51459ee75989f0227b5cf6f65ebf0';

module.exports = function (deployer, network, accounts) {
  return deployer
    .then(() => {
      return deployer.deploy(
        MerchantController,
        PriceUpdater.address,
        BablosCrowdsale.address)
    }).then(() => {
      return BablosCrowdsale.deployed().then(function (crowdsale) {
        crowdsale.setController(MerchantController.address);
      }).then(() => {
        return MerchantController.deployed().then(function (merchant) {
          merchant.transferOwnership(merchantAddress);
        })
      })
    });
};