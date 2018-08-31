const { should, REVERT_ERROR } = '../helpers/chaiHelper';
const BigNumber = require('bignumber.js');

const duration = {
  seconds: function(val) { return val},
  minutes: function(val) { return val * this.seconds(60) },
  hours:   function(val) { return val * this.minutes(60) },
  days:    function(val) { return val * this.hours(24) },
  weeks:   function(val) { return val * this.days(7) },
  years:   function(val) { return val * this.days(365)}
};

const BablosToken = artifacts.require('./tokens/BablosToken.sol');
const BablosCrowdsale = artifacts.require('./test/TestBablosCrowdsale.sol');
const BablosCrowdsaleWallet = artifacts.require('./wallets/BablosCrowdsaleWallet.sol');
const PriceUpdater = artifacts.require('./test/TestPriceUpdater.sol');
const MerchantController = artifacts.require('./merchant/MerchantController.sol');

const TOTAL_SUPPLY = new BigNumber(1000);
const rate = 50;
const softCap = 5 * 10**18; // 5 ETH
const hardCap = 4800 * 1000; // 4800 EUR

const minimumAmount = 10;

const teamPercent = 15;
const prAmount = 20;
const teamAmount = TOTAL_SUPPLY * 15 / 100 - prAmount;
const saleAmount = TOTAL_SUPPLY * 85 / 100;

contract('MerchantController', function(accounts) {
  let token, crowdsale, wallet, priceUpdater, merchant;
  let now, openingTime, closingTime;

  const beneficiary = accounts[1];

  beforeEach(async () => {
    now = new Date().getTime() / 1000 | 0;
    openingTime = now + duration.minutes(1);
    closingTime = now + duration.days(7);
    token = await BablosToken.new(
      'TEST',
      'TEST',
      0,
      TOTAL_SUPPLY);
    priceUpdater = await PriceUpdater.new(60, 5 * 60 * 1000);
    await priceUpdater.setPricesManually('400;0.001;100;2');
    crowdsale = await BablosCrowdsale.new(rate,
      token.address,
      openingTime,
      closingTime,
      softCap,
      hardCap,
      minimumAmount);
    await crowdsale.setPriceUpdater(priceUpdater.address);
    wallet = await BablosCrowdsaleWallet.new(token.address,
      crowdsale.address,
      priceUpdater.address,
      teamPercent,
      prAmount);
    await crowdsale.setWallet(wallet.address);
    await token.transfer(wallet.address, teamAmount);
    await token.transfer(crowdsale.address, saleAmount);
    await token.setSale(crowdsale.address);
    merchant = await MerchantController.new(priceUpdater.address, crowdsale.address);
    await crowdsale.setController(merchant.address);
    await crowdsale.setTime(now + duration.minutes(2));
  });

  it('calculate true price', async () => {
    let price = await merchant.calcPrice(0, 50); // ETH
    price.should.be.bignumber.equals(new BigNumber(1 * 10**18)); // 1 ETH
    price = await merchant.calcPrice(1, 50); // mBTC
    price.should.be.bignumber.equals(new BigNumber(0.4 * 10**6)); // 0.04 BTC
    price = await merchant.calcPrice(2, 50); // WME
    price.should.be.bignumber.equals(new BigNumber(400 * 10**6)); // 400 EUR
    price = await merchant.calcPrice(3, 50); // WMZ
    price.should.be.bignumber.equals(new BigNumber(800 * 10**6)); // 800 USD
    price = await merchant.calcPrice(4, 50); // WMR
    price.should.be.bignumber.equals(new BigNumber(40000 * 10**6)); // 40000 RUB
  });

  it('can buy tokens once', async () => {
    await merchant.buyTokens(beneficiary, 2, 80 * 1000, 10, 1); // WME
    let tokens = await token.balanceOf(beneficiary);
    tokens.should.be.bignumber.equals(new BigNumber(10));
    let totalInvested = await wallet.getTotalInvestedEur();
    totalInvested.should.be.bignumber.equals(new BigNumber(80 * 1000)); // 80 EUR
    await merchant.buyTokens(beneficiary, 2, 80 * 1000, 10, 1).should.be.rejectedWith(REVERT_ERROR);
    await merchant.buyTokens(beneficiary, 4, 8000 * 1000, 10, 2); // WMR
    tokens = await token.balanceOf(beneficiary);
    tokens.should.be.bignumber.equals(new BigNumber(20));
    totalInvested = await wallet.getTotalInvestedEur();
    totalInvested.should.be.bignumber.equals(new BigNumber(160 * 1000)); // 160 EUR
    await merchant.buyTokens(beneficiary, 2, 50, 10, 3, {from: beneficiary}).should.be.rejectedWith(REVERT_ERROR);
  });

});