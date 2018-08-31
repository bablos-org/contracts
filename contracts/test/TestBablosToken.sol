pragma solidity ^0.4.23;

import "../tokens/BablosToken.sol";

contract TestBablosToken is BablosToken {
  constructor(uint256 _totalSupply) public BablosToken("TEST", "TEST", 0, _totalSupply) {
  }

  function setFrozen(bool _value) external onlyOwner {
    frozen = _value;
  }
}