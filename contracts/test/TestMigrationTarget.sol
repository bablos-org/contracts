pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

import "../tokens/UpgradeableToken.sol";

/**
 * A sample token that is used as a migration testing target.
 *
 * This is not an actual token, but just a stub used in testing.
 */
contract TestMigrationTarget is StandardToken, UpgradeAgent {
  using SafeMath for uint256;

  UpgradeableToken public oldToken;

  uint256 public originalSupply;

  constructor (UpgradeableToken _oldToken) public {
    // Let's not set bad old token
    require(address(_oldToken) != 0);
    // Let's make sure we have something to migrate
    require(_oldToken.totalSupply() > 0);

    oldToken = _oldToken;
    originalSupply = _oldToken.totalSupply();
  }

  function upgradeFrom(address _from, uint256 _value) public {
    // only upgrade from oldToken
    require(msg.sender == address(oldToken)); 

    // Mint new tokens to the migrator
    totalSupply_ = totalSupply_.add(_value);
    balances[_from] = balances[_from].add(_value);
    emit Transfer(address(0), _from, _value);
  }
}