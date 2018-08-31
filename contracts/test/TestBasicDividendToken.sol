pragma solidity ^0.4.23;

import "../tokens/BasicDividendToken.sol";

contract TestBasicDividendToken is BasicDividendToken {
  constructor(uint256 _totalSupply) public {
    totalSupply_ = _totalSupply;
    balances[msg.sender] = totalSupply_;
  }
}