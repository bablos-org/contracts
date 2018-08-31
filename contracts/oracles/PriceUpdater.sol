pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

import "../lib/strings.sol";
import "../lib/oraclizeAPI.sol";

import "./PriceUpdaterInterface.sol";

contract PriceUpdater is usingOraclize, Ownable, PriceUpdaterInterface {
  using SafeMath for uint;
  using strings for *;

  uint public priceLastUpdate;
  uint public priceLastUpdateRequest;
  uint public priceUpdateInterval;
  uint public callbackGas = 150000;
  uint public maxInterval;

  constructor (uint _priceUpdateInterval, uint _maxInterval) public {
    priceUpdateInterval = _priceUpdateInterval;
    maxInterval = _maxInterval;
    price[uint(PriceUpdaterInterface.Currency.WME)] = 1000;
  }

  function withdraw() public onlyOwner {
    require(address(this).balance > 0);
    owner.transfer(address(this).balance);
  }

  function updatePrice() public payable {
    require(msg.sender == oraclize_cbAddress() || msg.sender == owner);
    require(updateRequestExpired());
    
    oraclize_query(
      priceUpdateInterval,
      "URL",
      "https://rates.web.money/rates/getrates.ashx?pairs=eth-eur_eur-wmx_eur-rub_eur-usd",
      callbackGas
    );
    priceLastUpdateRequest = getTime();
  }

  /// @notice Called on price update by Oraclize
  function __callback(bytes32 myid, string result, bytes proof) public {
    require(msg.sender == oraclize_cbAddress());
    setPrices(result);
    updatePrice();
  }

  function() external payable {
  }

  /// @notice set the price of currencies in euro, called in case we don't get oraclize data
  ///         for more than double the update interval
  /// @param _prices Currency rates in format "ethPrice;btcPrice;wmrPrice;wmzPrice" in euro
  function setPricesManually(string _prices) external onlyOwner {
    // allow for owners to change the price anytime if the price has expired
    require(priceExpired() || updateRequestExpired());
    setPrices(_prices);
  }

  function setPrices(string _prices) internal {
    var s = _prices.toSlice();

    price[uint(PriceUpdaterInterface.Currency.ETH)] = parseUint(s.split(";".toSlice()).toString(), decimalPrecision);
    price[uint(PriceUpdaterInterface.Currency.BTC)] = parseUint(s.split(";".toSlice()).toString(), decimalPrecision);
    price[uint(PriceUpdaterInterface.Currency.WMR)] = parseUint(s.split(";".toSlice()).toString(), decimalPrecision);
    price[uint(PriceUpdaterInterface.Currency.WMZ)] = parseUint(s.split(";".toSlice()).toString(), decimalPrecision);
    price[uint(PriceUpdaterInterface.Currency.WMX)] = price[uint(PriceUpdaterInterface.Currency.BTC)];

    priceLastUpdate = getTime();
  }

  function parseUint(string _a, uint _b) pure internal returns (uint) {
    bytes memory bresult = bytes(_a);
    uint mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
        if (decimals) {
          if (_b == 0) break;
          else _b--;
        }
        mint *= 10;
        mint += uint(bresult[i]) - 48;
      } else if (bresult[i] == 46) {
        decimals = true;
      }
    }
    if (_b > 0) mint *= uint(10 ** _b);
    return mint;
  }

  function setOraclizeGasPrice(uint256 _gasPrice) external onlyOwner {
    oraclize_setCustomGasPrice(_gasPrice);
  }

  function setOraclizeGasLimit(uint _callbackGas) external onlyOwner {
    callbackGas = _callbackGas;
  }

  function setPriceUpdateInterval(uint _priceUpdateInterval) external onlyOwner {
    priceUpdateInterval = _priceUpdateInterval;
  }

  function setMaxInterval(uint _maxInterval) external onlyOwner {
    maxInterval = _maxInterval;
  }

  /// @dev Check that double the update interval has passed since last successful price update
  function priceExpired() public view returns (bool) {
    return (getTime() > priceLastUpdate + 2 * priceUpdateInterval);
  }

  /// @dev Check that price update was requested more than max interval ago
  function updateRequestExpired() public view returns (bool) {
    return getTime() >= (priceLastUpdateRequest + maxInterval);
  }

  /// @dev to be overridden in tests
  function getTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return now;
  }
}