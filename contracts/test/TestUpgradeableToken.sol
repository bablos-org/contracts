pragma solidity ^0.4.23;

import "../tokens/UpgradeableToken.sol";

contract TestUpgradeableToken is UpgradeableToken {
  constructor(uint256 _totalSupply)  public UpgradeableToken(msg.sender) {
    totalSupply_ = _totalSupply;
    balances[msg.sender] = totalSupply_;
  }
}