const { should, REVERT_ERROR } = './helpers/chaiHelper';
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

const TOTAL_SUPPLY = new BigNumber(1000);
const rate = 50;
const softCap = 5 * 10**18; // 5 ETH
const hardCap = 4800 * 1000; // 4800 EUR

const minimumAmount = 10;

const teamPercent = 15;
const prAmount = 20;
const teamAmount = TOTAL_SUPPLY * 15 / 100 - prAmount;
const saleAmount = TOTAL_SUPPLY * 85 / 100;

contract('BablosCrowdsale', function(accounts) {
  let token, crowdsale, wallet, priceUpdater;
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
  });

  it('cannot buy tokens before crowdsale start', async () => {
    await crowdsale.setTime(now - duration.days(1));
    await crowdsale.buyTokens(beneficiary, {value: 10**18}).should.be.rejectedWith(REVERT_ERROR);
    await crowdsale.setTime(now + duration.minutes(2));
    await crowdsale.buyTokens(beneficiary, {value: 10**18});
    state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(1)); // ACTIVE
    let tokens = await token.balanceOf(beneficiary);
    tokens.should.be.bignumber.equals(new BigNumber(50));
  });

  it('cannot buy tokens less than minimum amount', async () => {
    await crowdsale.setTime(now + duration.minutes(2));
    await crowdsale.buyTokens(beneficiary, {value: 0.001 * 10**18}).should.be.rejectedWith(REVERT_ERROR);
  });

  it('cannot buy tokens more than crowdsale balance', async () => {
    await crowdsale.setTime(now + duration.minutes(2));
    await crowdsale.buyTokens(beneficiary, {value: 90 * 10**18}).should.be.rejectedWith(REVERT_ERROR);
  });

  it('can reach soft cap', async () => {
    await crowdsale.setTime(now + duration.minutes(2));
    let state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(0)); // INIT
    state = await wallet.state();
    state.should.be.bignumber.equals(new BigNumber(0)); // GATHERING

    await crowdsale.buyTokens(beneficiary, {value: 5 * 10**18}); // 5 ETH
    state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(3)); // SOFT_CAP_REACHED
    state = await wallet.state();
    state.should.be.bignumber.equals(new BigNumber(2)); // SUCCEEDED
  });

  it('can reach hard cap', async () => {
    await crowdsale.setTime(now + duration.minutes(2));
    let state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(0)); // INIT
    state = await wallet.state();
    state.should.be.bignumber.equals(new BigNumber(0)); // GATHERING

    await crowdsale.buyTokens(beneficiary, {value: 12 * 10**18}); // 12 ETH
    
    state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(5)); // SUCCEEDED
    state = await wallet.state();
    state.should.be.bignumber.equals(new BigNumber(2)); // SUCCEEDED
  });

  it('failed when soft cap not reached and time is over', async () => {
    await crowdsale.setTime(now + duration.minutes(2));
    let state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(0)); // INIT
    state = await wallet.state();
    state.should.be.bignumber.equals(new BigNumber(0)); // GATHERING

    await crowdsale.buyTokens(beneficiary, {value: 1 * 10**18}); // 1 ETH
    await crowdsale.setTime(now + duration.days(8));
    await crowdsale.buyTokens(beneficiary, {value: 1 * 10**18});
    state = await crowdsale.state();
    state.should.be.bignumber.equals(new BigNumber(4)); // FAILED
    state = await wallet.state();
    state.should.be.bignumber.equals(new BigNumber(1)); // REFUNDING
  });

  it('can buy tokens externally only with merchant controller', async () => {
    const merchantController = accounts[2];
    await crowdsale.setController(merchantController);
    await crowdsale.setTime(now + duration.minutes(2));
    await crowdsale.externalBuyToken(beneficiary, 2, 80, 10, {from: merchantController}); // WME
    let tokens = await token.balanceOf(beneficiary);
    tokens.should.be.bignumber.equals(new BigNumber(10));
    await crowdsale.externalBuyToken(beneficiary, 2, 80, 10).should.be.rejectedWith(REVERT_ERROR);
  });
});