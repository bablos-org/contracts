const BablosToken = artifacts.require('./tokens/BablosToken.sol');
const BablosCrowdsale = artifacts.require('./crowdsales/BablosCrowdsale.sol');
const PriceUpdater = artifacts.require('./oracles/PriceUpdater.sol');

const duration = {
    seconds: function(val) { return val},
    minutes: function(val) { return val * this.seconds(60) },
    hours:   function(val) { return val * this.minutes(60) },
    days:    function(val) { return val * this.hours(24) },
    weeks:   function(val) { return val * this.days(7) },
    years:   function(val) { return val * this.days(365)}
};

const rate = 50;
const softCap = 2000 * 10**18; // 2000 ETH
const hardCap = 3360000 * 1000; // 3 3600 000 EUR

const minimumAmount = 10;
const now = new Date().getTime() / 1000 | 0;

const openingTime = now + duration.minutes(15);
const closingTime = now + duration.days(93);


module.exports = function(deployer, network, accounts) {
  return deployer
    .then(() => {
      return deployer.deploy(
        BablosCrowdsale,
        rate,
        BablosToken.address,
        openingTime,
        closingTime,
        softCap,
        hardCap,
        minimumAmount);
    }).then(() => {
      return BablosCrowdsale.deployed().then(function (crowdsale) {
        crowdsale.setPriceUpdater(PriceUpdater.address);
      });
    });
};