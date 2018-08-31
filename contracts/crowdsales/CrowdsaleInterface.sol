pragma solidity ^0.4.23;

import "../oracles/PriceUpdaterInterface.sol";

contract CrowdsaleInterface {
  uint public rate;
  uint public minimumAmount;

  function externalBuyToken(address _beneficiary, PriceUpdaterInterface.Currency _currency, uint _amount, uint _tokens) external;
}