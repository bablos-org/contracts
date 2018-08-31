const { should, REVERT_ERROR } = '../helpers/chaiHelper';
const BigNumber = require('bignumber.js');

const BasicDividend = artifacts.require('./dividends/BasicDividend.sol');
const TestBasicDividendToken = artifacts.require('./test/TestBasicDividendToken.sol');

const TOTAL_SUPPLY = new BigNumber(1000);

contract('TestBasicDividendToken', function(accounts) {
  let token, dividend;

  beforeEach(async () => {
    token = await TestBasicDividendToken.new(TOTAL_SUPPLY);
    dividend = await BasicDividend.new(token.address);
    await token.setDividends(dividend.address);
  });

  it('dividend can be set on released token', async function() {
    (await token.dividends()).should.be.equal(dividend.address);
  })
});