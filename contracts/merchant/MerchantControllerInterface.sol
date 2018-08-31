pragma solidity ^0.4.23;

import "../oracles/PriceUpdaterInterface.sol";

contract MerchantControllerInterface {
  mapping(uint => uint) public totalInvested;
  mapping(uint => bool) public paymentId;

  function calcPrice(PriceUpdaterInterface.Currency _currency, uint _tokens) public view returns(uint);
  function buyTokens(address _beneficiary, PriceUpdaterInterface.Currency _currency, uint _amount, uint _tokens, uint _paymentId) external;
}