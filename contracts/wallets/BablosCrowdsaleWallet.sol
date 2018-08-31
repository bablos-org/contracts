pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ReentrancyGuard.sol";

import "../tokens/BablosTokenInterface.sol";
import "./BablosCrowdsaleWalletInterface.sol";
import "../oracles/PriceUpdaterInterface.sol";

contract BablosCrowdsaleWallet is BablosCrowdsaleWalletInterface, Ownable, ReentrancyGuard {
  using SafeMath for uint;

  modifier requiresState(State _state) {
    require(state == _state);
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }
  
  constructor(
    BablosTokenInterface _token, 
    address _controller, 
    PriceUpdaterInterface _priceUpdater, 
    uint _teamPercent, 
    uint _prTokens) 
      public 
  {
    token = _token;
    controller = _controller;
    priceUpdater = _priceUpdater;
    teamPercent = _teamPercent;
    prTokens = _prTokens;
  }

  function getTotalInvestedEther() external view returns (uint) {
    uint etherPrice = priceUpdater.price(uint(PriceUpdaterInterface.Currency.ETH));
    uint totalInvestedEth = totalInvested[uint(PriceUpdaterInterface.Currency.ETH)];
    uint totalAmount = _totalInvestedNonEther();
    return totalAmount.mul(1 ether).div(etherPrice).add(totalInvestedEth);
  }

  function getTotalInvestedEur() external view returns (uint) {
    uint totalAmount = _totalInvestedNonEther();
    uint etherAmount = totalInvested[uint(PriceUpdaterInterface.Currency.ETH)]
      .mul(priceUpdater.price(uint(PriceUpdaterInterface.Currency.ETH)))
      .div(1 ether);
    return totalAmount.add(etherAmount);
  }

  /// @dev total invested in EUR within ETH amount
  function _totalInvestedNonEther() internal view returns (uint) {
    uint totalAmount;
    uint precision = priceUpdater.decimalPrecision();
    // BTC
    uint btcAmount = totalInvested[uint(PriceUpdaterInterface.Currency.BTC)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.BTC)));
    totalAmount = totalAmount.add(btcAmount);
    // WME
    uint wmeAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WME)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WME)));
    totalAmount = totalAmount.add(wmeAmount);
    // WMZ
    uint wmzAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WMZ)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WMZ)));
    totalAmount = totalAmount.add(wmzAmount);
    // WMR
    uint wmrAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WMR)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WMR)));
    totalAmount = totalAmount.add(wmrAmount);
    // WMX
    uint wmxAmount = totalInvested[uint(PriceUpdaterInterface.Currency.WMX)]
      .mul(10 ** precision)
      .div(priceUpdater.price(uint(PriceUpdaterInterface.Currency.WMX)));
    totalAmount = totalAmount.add(wmxAmount);
    return totalAmount;
  }

  function changeState(State _newState) external onlyController {
    assert(state != _newState);

    if (State.GATHERING == state) {
      assert(_newState == State.REFUNDING || _newState == State.SUCCEEDED);
    } else {
      assert(false);
    }

    state = _newState;
    emit StateChanged(state);
  }

  function invested(
    address _investor,
    uint _tokenAmount,
    PriceUpdaterInterface.Currency _currency,
    uint _amount) 
      external 
      payable
      onlyController
  {
    require(state == State.GATHERING || state == State.SUCCEEDED);
    uint amount;
    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      amount = msg.value;
      weiBalances[_investor] = weiBalances[_investor].add(amount);
    } else {
      amount = _amount;
    }
    require(amount != 0);
    require(_tokenAmount != 0);
    assert(_investor != controller);

    // register investor
    if (tokenBalances[_investor] == 0) {
      investors.push(_investor);
    }

    // register payment
    totalInvested[uint(_currency)] = totalInvested[uint(_currency)].add(amount);
    tokenBalances[_investor] = tokenBalances[_investor].add(_tokenAmount);

    emit Invested(_investor, _currency, amount, _tokenAmount);
  }

  function withdrawEther(uint _value)
    external
    onlyOwner
    requiresState(State.SUCCEEDED) 
  {
    require(_value > 0 && address(this).balance >= _value);
    owner.transfer(_value);
    emit EtherWithdrawan(owner, _value);
  }

  function withdrawTokens(uint _value)
    external
    onlyOwner
    requiresState(State.REFUNDING)
  {
    require(_value > 0 && token.balanceOf(address(this)) >= _value);
    token.transfer(owner, _value);
  }

  function withdrawPayments()
    external
    nonReentrant
    requiresState(State.REFUNDING)
  {
    address payee = msg.sender;
    uint payment = weiBalances[payee];
    uint tokens = tokenBalances[payee];

    // check that there is some ether to withdraw
    require(payment != 0);
    // check that the contract holds enough ether
    require(address(this).balance >= payment);
    // check that the investor (payee) gives back all tokens bought during ICO
    require(token.allowance(payee, address(this)) >= tokenBalances[payee]);

    totalInvested[uint(PriceUpdaterInterface.Currency.ETH)] = totalInvested[uint(PriceUpdaterInterface.Currency.ETH)].sub(payment);
    weiBalances[payee] = 0;
    tokenBalances[payee] = 0;

    token.transferFrom(payee, address(this), tokens);

    payee.transfer(payment);
    emit RefundSent(payee, payment);
  }

  function getInvestorsCount() external view returns (uint) { return investors.length; }

  function detachController() external onlyController {
    address was = controller;
    controller = address(0);
    emit ControllerRetired(was);
  }

  function unholdTeamTokens() external onlyController {
    uint tokens = token.balanceOf(address(this));
    if (state == State.SUCCEEDED) {
      uint soldTokens = token.totalSupply().sub(token.balanceOf(address(this))).sub(prTokens);
      uint soldPecent = 100 - teamPercent;
      uint teamShares = soldTokens.mul(teamPercent).div(soldPecent).sub(prTokens);
      token.transfer(owner, teamShares);
      token.burn(token.balanceOf(address(this)));
    } else {
      token.approve(owner, tokens);
    }
  }
}