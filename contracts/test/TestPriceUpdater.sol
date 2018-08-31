pragma solidity ^0.4.23;

import "../oracles/PriceUpdater.sol";

contract TestPriceUpdater is PriceUpdater {
  uint256 internal _now;

  constructor (uint _priceUpdateInterval, uint _maxInterval) public PriceUpdater(_priceUpdateInterval, _maxInterval) {
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