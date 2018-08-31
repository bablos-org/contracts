pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ReentrancyGuard.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

import "../crowdsales/CrowdsaleInterface.sol";
import "../oracles/PriceUpdaterInterface.sol";
import "./MerchantControllerInterface.sol";

contract MerchantController is MerchantControllerInterface, ReentrancyGuard, Ownable {
  using SafeMath for uint;

  PriceUpdaterInterface public priceUpdater;
  CrowdsaleInterface public crowdsale;

  constructor(PriceUpdaterInterface _priceUpdater, CrowdsaleInterface _crowdsale) public  {
    priceUpdater = _priceUpdater;
    crowdsale = _crowdsale;
  }

  function calcPrice(PriceUpdaterInterface.Currency _currency, uint _tokens) 
      public 
      view 
      returns(uint) 
  {
    uint priceInWei = _tokens.mul(1 ether).div(crowdsale.rate());
    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      return priceInWei;
    }
    uint etherPrice = priceUpdater.price(uint(PriceUpdaterInterface.Currency.ETH));
    uint priceInEur = priceInWei.mul(etherPrice).div(1 ether);

    uint currencyPrice = priceUpdater.price(uint(_currency));
    uint tokensPrice = priceInEur.mul(currencyPrice);
    
    return tokensPrice;
  }

  function buyTokens(
    address _beneficiary,
    PriceUpdaterInterface.Currency _currency,
    uint _amount,
    uint _tokens,
    uint _paymentId)
      external
      onlyOwner
      nonReentrant
  {
    require(_beneficiary != address(0));
    require(_currency != PriceUpdaterInterface.Currency.ETH);
    require(_amount != 0);
    require(_tokens >= crowdsale.minimumAmount());
    require(_paymentId != 0);
    require(!paymentId[_paymentId]);
    paymentId[_paymentId] = true;
    crowdsale.externalBuyToken(_beneficiary, _currency, _amount, _tokens);
  }
}