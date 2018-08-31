const { should, REVERT_ERROR } = './helpers/chaiHelper';
const BigNumber = require('bignumber.js');

const BasicDividend = artifacts.require('./dividends/BasicDividend.sol');
const TestBasicDividendToken = artifacts.require('./test/TestBasicDividendToken.sol');

const TOTAL_SUPPLY = new BigNumber(1000);

contract('BasicDividend', function(accounts) {
  let token, dividend, owner, investor;

  beforeEach(async function () {
    token = await TestBasicDividendToken.new(TOTAL_SUPPLY);
    dividend = await BasicDividend.new(token.address);
    await token.setDividends(dividend.address);
    owner = accounts[0];
    investor = accounts[1];
  });

  it('increases total dividends after payment', async function() {
    const dividendPayment = new BigNumber(10);
    await dividend.putProfit({value: dividendPayment});
    const totalDividends = await dividend.totalDividends();
    totalDividends.should.be.bignumber.equals(dividendPayment);
    const hasDividends = await dividend.hasDividends();
    hasDividends.should.be.true;
  });

  it('distributes the correct dividends', async function () {
    await token.transfer(investor, TOTAL_SUPPLY / 2);
    await dividend.putProfit({value: 1 * 10**18}); // 0 Ether
    const investorBalance = await dividend.dividendBalanceOf(investor);
    investorBalance.should.be.bignumber.equals(new BigNumber(0.5 * 10**18));
  });

  it('does not change the share when tokens are transferred', async function(){
    await token.transfer(investor, TOTAL_SUPPLY / 2);
    await dividend.putProfit({value: 1 * 10**18}); // 1 Ether
    let ownerBalance = await dividend.dividendBalanceOf(owner);
    let investorBalance = await dividend.dividendBalanceOf(investor);
    ownerBalance.should.be.bignumber.equals(new BigNumber(0.5 * 10**18));
    investorBalance.should.be.bignumber.equals(new BigNumber(0.5 * 10**18));
    await token.transfer(investor, TOTAL_SUPPLY / 2);
    investorBalance = await dividend.dividendBalanceOf(investor);
    ownerBalance = await dividend.dividendBalanceOf(owner);
    ownerBalance.should.be.bignumber.equals(new BigNumber(0.5 * 10**18));
    investorBalance.should.be.bignumber.equals(new BigNumber(0.5 * 10**18));
  });

  it('only token contract can', async function(){
    await token.transfer(investor, TOTAL_SUPPLY / 2);
    await dividend.putProfit({value: 1 * 10**18}); // 1 Ether
    await dividend.saveUnclaimedDividends(investor).should.be.rejectedWith(REVERT_ERROR);
  });

  it('can claim dividends', async function(){
    await token.transfer(investor, TOTAL_SUPPLY / 2);
    await dividend.putProfit({value: 1 * 10**18}); // 1 Ether
    let investorDividends = await dividend.dividendBalanceOf(investor);
    const investorBalanceBeforeDividends = await web3.eth.getBalance(investor);
    await dividend.claimDividends({from: investor});
    const investorBalanceAfterDividends = await web3.eth.getBalance(investor);
    investorBalanceAfterDividends.should.be.bignumber.greaterThan(investorBalanceBeforeDividends);
    const claimedDividends = await dividend.claimedDividendsOf(investor);
    claimedDividends.should.be.bignumber.equals(new BigNumber(0.5 * 10**18));
    investorDividends = await dividend.dividendBalanceOf(investor);
    investorDividends.should.be.bignumber.equals(new BigNumber(0));
  });
});