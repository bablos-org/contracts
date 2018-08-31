const { should, REVERT_ERROR } = './helpers/chaiHelper';
const BigNumber = require('bignumber.js');
const EthCrypto = require('eth-crypto');

const InvestorDividend = artifacts.require('./dividends/InvestorDividend.sol');
const TestBablosToken = artifacts.require('./tokens/TestBablosToken.sol');

const TOTAL_SUPPLY = new BigNumber(1000);
const privateKey = 'YOUR-PRIVATE-HERE';
const publicKey = EthCrypto.publicKeyByPrivateKey('0x' + privateKey);

contract('InvestorDividend', function(accounts) {
  let token, dividend, owner, investor;

  beforeEach(async function () {
    token = await TestBablosToken.new(TOTAL_SUPPLY);
    await token.setFrozen(false);
    dividend = await InvestorDividend.new(token.address, 10);
    await dividend.setPublicKey(publicKey);
    owner = accounts[0];
    investor = accounts[1];
    await token.transfer(investor, TOTAL_SUPPLY / 2);
  });

  it('can set data and owner can accept request', async function() {
    const data = "Hello, World!";
    let encryptedData = await EthCrypto.encryptWithPublicKey(publicKey, data);
    encryptedData = EthCrypto.cipher.stringify(encryptedData);
    await token.approve(dividend.address, TOTAL_SUPPLY / 2, {from: investor});
    await dividend.createRequest(encryptedData, {from: investor});
    let dividendBalance = await token.balanceOf(dividend.address);
    dividendBalance.should.be.bignumber.equals(TOTAL_SUPPLY / 2);
    let requestData = await dividend.request(investor);
    encryptedData = EthCrypto.cipher.parse(requestData[1]);
    const decryptedData = await EthCrypto.decryptWithPrivateKey(privateKey, encryptedData);
    decryptedData.should.be.equals(data);

    await dividend.approveRequest(investor);
    requestData = await dividend.request(investor);
    requestData[2].should.be.bignumber.equals(1); // APPROVED
    const totalSupply = await token.totalSupply();
    totalSupply.should.be.bignumber.equals(TOTAL_SUPPLY / 2);
  });
});