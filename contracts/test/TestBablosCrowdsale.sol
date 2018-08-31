pragma solidity ^0.4.23;

import "../crowdsales/BablosCrowdsale.sol";

contract TestBablosCrowdsale is BablosCrowdsale {
  uint256 internal _now;

  constructor(
    uint256 _rate, 
    BablosTokenInterface _token,
    uint256 _openingTime, 
    uint256 _closingTime, 
    uint256 _softCap,
    uint256 _hardCap,
    uint256 _minimumAmount) 
    public
    BablosCrowdsale(_rate, _token, _openingTime, _closingTime, _softCap, _hardCap, _minimumAmount)
  {
    // solium-disable-next-line security/no-block-members
    _now = now;
  }

  function setTime(uint256 _time) public {
    _now = _time;
  }

  function getTime() internal view returns (uint256) {
    return _now;
  }
}