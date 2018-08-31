const { should, REVERT_ERROR } = './helpers/chaiHelper';
const BigNumber = require('bignumber.js');
const TestUpgradeableToken = artifacts.require('./test/TestUpgradeableToken.sol');
const TestMigrationTarget = artifacts.require('./test/TestMigrationTarget.sol');

const TOTAL_SUPPLY = new BigNumber(1000 * 10**18);

contract('TestUpgradeableToken', function (accounts) {
  let upgradeableToken, upgradeAgent, upgradeAgent2;

  beforeEach(async () => {
    upgradeableToken = await TestUpgradeableToken.new(TOTAL_SUPPLY);
    upgradeAgent = await TestMigrationTarget.new(upgradeableToken.address);
    upgradeAgent2 = await TestMigrationTarget.new(upgradeableToken.address);
  });

  it('upgrade agent can be set on a released token', async function () {
    const totalSupply = await upgradeableToken.totalSupply();
    (await upgradeAgent.isUpgradeAgent()).should.be.true;
    (await upgradeableToken.canUpgrade()).should.be.true;
    (await upgradeableToken.upgradeMaster()).should.be.equal(accounts[0]);
    (await upgradeAgent.oldToken()).should.be.equal(upgradeableToken.address);
    (await upgradeAgent.originalSupply()).should.be.bignumber.equal(totalSupply);
    (await upgradeableToken.getUpgradeState()).should.be.bignumber.equal(2); // WaitingForAgent
    await upgradeableToken.setUpgradeAgent(upgradeAgent.address);
    (await upgradeableToken.getUpgradeState()).should.be.bignumber.equal(3); // ReadyToUpgrade
  });

  it('cannot set the upgrade agent with not owner account on a released token', async function() {
    await upgradeableToken.setUpgradeAgent(upgradeAgent.address, {from: accounts[1]}).should.be.rejectedWith(REVERT_ERROR);
  });

  it('can changes the upgrade master', async function() {
    await upgradeableToken.setUpgradeMaster(accounts[1]);
    await upgradeableToken.setUpgradeAgent(upgradeAgent.address, {'from': accounts[1]})
  });

  it('can upgrades some of tokens', async function() {
    await upgradeableToken.setUpgradeAgent(upgradeAgent.address);
    await upgradeableToken.transfer(accounts[1], new BigNumber(300 * 10**18));
    const toUpgrade = new BigNumber(500 * 10**18);
    const beginTokens = await upgradeableToken.balanceOf(accounts[0]);
    const supplyStart = await upgradeableToken.totalSupply();
    beginTokens.should.be.bignumber.greaterThan(toUpgrade);
    await upgradeableToken.upgrade(toUpgrade);
    (await upgradeableToken.getUpgradeState()).should.be.bignumber.equal(4); // Upgrading
    (await upgradeableToken.totalSupply()).should.be.bignumber.equal(supplyStart.minus(toUpgrade));
    (await upgradeAgent.totalSupply()).should.be.bignumber.equal(toUpgrade);
    (await upgradeableToken.totalUpgraded()).should.be.bignumber.equal(toUpgrade);

    const ownerBalance = new BigNumber(beginTokens).minus(toUpgrade);
    (await upgradeableToken.balanceOf(accounts[0])).should.be.bignumber.equal(ownerBalance);
    (await upgradeAgent.balanceOf(accounts[0])).should.be.bignumber.equal(toUpgrade);
  });

  it('can upgrades all tokens of two owners', async function() {
    await upgradeableToken.transfer(accounts[1], new BigNumber(300 * 10**18));

    const toUpgradeOwner = await upgradeableToken.balanceOf(accounts[0]);
    const toUpgradeCustomer = await upgradeableToken.balanceOf(accounts[1]);
    const supplyStart = await upgradeableToken.totalSupply();

    await upgradeableToken.setUpgradeAgent(upgradeAgent.address);

    await upgradeableToken.upgrade(toUpgradeOwner);
    await upgradeableToken.upgrade(toUpgradeCustomer, {'from': accounts[1]});

    (await upgradeableToken.getUpgradeState()).should.be.bignumber.equal(4); // Upgrading
    (await upgradeableToken.totalSupply()).should.be.bignumber.equal(0);

    (await upgradeAgent.totalSupply()).should.be.bignumber.equal(supplyStart);
    (await upgradeableToken.totalUpgraded()).should.be.bignumber.equal(supplyStart);

    (await upgradeAgent.balanceOf(accounts[0])).should.be.bignumber.equal(toUpgradeOwner);
    (await upgradeAgent.balanceOf(accounts[1])).should.be.bignumber.equal(toUpgradeCustomer);
  });

  it('cannot upgrade more tokens than it has', async function() {
    const customerBalance = new BigNumber(300 * 10**18);
    await upgradeableToken.setUpgradeAgent(upgradeAgent.address);
    await upgradeableToken.transfer(accounts[1], customerBalance);
    (await upgradeableToken.balanceOf(accounts[1])).should.be.bignumber.equal(customerBalance);
    const overBalance = new BigNumber(600 * 10**18);
    await upgradeableToken.upgrade(overBalance, {'from': accounts[1]}).should.be.rejectedWith(REVERT_ERROR);
  });

  it('upgrade agent cannot be changed after the ugprade has begun', async function() {
    const customerBalance = new BigNumber(300 * 10**18);
    await upgradeableToken.setUpgradeAgent(upgradeAgent.address);
    await upgradeableToken.transfer(accounts[1], customerBalance);
    await upgradeableToken.upgrade(customerBalance, {'from': accounts[1]});
    await upgradeableToken.setUpgradeAgent(upgradeAgent2.address).should.be.rejectedWith(REVERT_ERROR);
  });
})