pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ReentrancyGuard.sol";

import "../tokens/BablosTokenInterface.sol";
import "../wallets/BablosCrowdsaleWalletInterface.sol";
import "../oracles/PriceUpdaterInterface.sol";

contract BablosCrowdsale is ReentrancyGuard, Ownable {
  using SafeMath for uint;

  enum SaleState { INIT, ACTIVE, PAUSED, SOFT_CAP_REACHED, FAILED, SUCCEEDED }

  SaleState public state = SaleState.INIT;

  // The token being sold
  BablosTokenInterface public token;

  // Address where funds are collected
  BablosCrowdsaleWalletInterface public wallet;

  // How many tokens per 1 ether
  uint public rate;

  uint public openingTime;
  uint public closingTime;

  uint public tokensSold;
  uint public tokensSoldExternal;

  uint public softCap;
  uint public hardCap;
  uint public minimumAmount;

  address public controller;
  PriceUpdaterInterface public priceUpdater;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param currency of paid value
   * @param value paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint currency,
    uint value,
    uint amount
  );

  event StateChanged(SaleState _state);
  event FundTransfer(address _backer, uint _amount);

  // MODIFIERS

  modifier requiresState(SaleState _state) {
    require(state == _state);
    _;
  }

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  /// @dev triggers some state changes based on current time
  /// @param _client optional refund parameter
  /// @param _payment optional refund parameter
  /// @param _currency currency
  /// note: function body could be skipped!
  modifier timedStateChange(address _client, uint _payment, PriceUpdaterInterface.Currency _currency) {
    if (SaleState.INIT == state && getTime() >= openingTime) {
      changeState(SaleState.ACTIVE);
    }

    if ((state == SaleState.ACTIVE || state == SaleState.SOFT_CAP_REACHED) && getTime() >= closingTime) {
      finishSale();

      if (_currency == PriceUpdaterInterface.Currency.ETH && _payment > 0) {
        _client.transfer(_payment);
      }
    } else {
      _;
    }
  }

  constructor(
    uint _rate, 
    BablosTokenInterface _token,
    uint _openingTime, 
    uint _closingTime, 
    uint _softCap,
    uint _hardCap,
    uint _minimumAmount) 
    public
  {
    require(_rate > 0);
    require(_token != address(0));
    require(_openingTime >= getTime());
    require(_closingTime > _openingTime);
    require(_softCap > 0);
    require(_hardCap > 0);

    rate = _rate;
    token = _token;
    openingTime = _openingTime;
    closingTime = _closingTime;
    softCap = _softCap;
    hardCap = _hardCap;
    minimumAmount = _minimumAmount;
  }

  function setWallet(BablosCrowdsaleWalletInterface _wallet) external onlyOwner {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function setController(address _controller) external onlyOwner {
    require(_controller != address(0));
    controller = _controller;
  }

  function setPriceUpdater(PriceUpdaterInterface _priceUpdater) external onlyOwner {
    require(_priceUpdater != address(0));
    priceUpdater = _priceUpdater;
  }

  function isActive() public view returns (bool active) {
    return state == SaleState.ACTIVE || state == SaleState.SOFT_CAP_REACHED;
  }

  /**
   * @dev fallback function
   */
  function () external payable {
    require(msg.data.length == 0);
    buyTokens(msg.sender);
  }

  /**
   * @dev token purchase
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {
    uint weiAmount = msg.value;

    require(_beneficiary != address(0));
    require(weiAmount != 0);

    // calculate token amount to be created
    uint tokens = _getTokenAmount(weiAmount);

    require(tokens >= minimumAmount && token.balanceOf(address(this)) >= tokens);

    _internalBuy(_beneficiary, PriceUpdaterInterface.Currency.ETH, weiAmount, tokens);
  }

  /**
   * @dev external token purchase (BTC and WebMoney). Only allowed for merchant controller
   * @param _beneficiary Address performing the token purchase
   * @param _tokens Quantity of purchased tokens
   */
  function externalBuyToken(
    address _beneficiary, 
    PriceUpdaterInterface.Currency _currency, 
    uint _amount, 
    uint _tokens)
      external
      onlyController
  {
    require(_beneficiary != address(0));
    require(_tokens >= minimumAmount && token.balanceOf(address(this)) >= _tokens);
    require(_amount != 0);

    _internalBuy(_beneficiary, _currency, _amount, _tokens);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate).div(1 ether);
  }

  function _internalBuy(
    address _beneficiary, 
    PriceUpdaterInterface.Currency _currency, 
    uint _amount, 
    uint _tokens)
      internal
      nonReentrant
      timedStateChange(_beneficiary, _amount, _currency)
  {
    require(isActive());
    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      tokensSold = tokensSold.add(_tokens);
    } else {
      tokensSoldExternal = tokensSoldExternal.add(_tokens);
    }
    token.transfer(_beneficiary, _tokens);

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      uint(_currency),
      _amount,
      _tokens
    );

    if (_currency == PriceUpdaterInterface.Currency.ETH) {
      wallet.invested.value(_amount)(_beneficiary, _tokens, _currency, _amount);
      emit FundTransfer(_beneficiary, _amount);
    } else {
      wallet.invested(_beneficiary, _tokens, _currency, _amount);
    }
    
    // check if soft cap reached
    if (state == SaleState.ACTIVE && wallet.getTotalInvestedEther() >= softCap) {
      changeState(SaleState.SOFT_CAP_REACHED);
    }

    // check if all tokens are sold
    if (token.balanceOf(address(this)) < minimumAmount) {
      finishSale();
    }

    // check if hard cap reached
    if (state == SaleState.SOFT_CAP_REACHED && wallet.getTotalInvestedEur() >= hardCap) {
      finishSale();
    }
  }

  function finishSale() private {
    if (wallet.getTotalInvestedEther() < softCap) {
      changeState(SaleState.FAILED);
    } else {
      changeState(SaleState.SUCCEEDED);
    }
  }

  /// @dev performs only allowed state transitions
  function changeState(SaleState _newState) private {
    require(state != _newState);

    if (SaleState.INIT == state) {
      assert(SaleState.ACTIVE == _newState);
    } else if (SaleState.ACTIVE == state) {
      assert(
        SaleState.PAUSED == _newState ||
        SaleState.SOFT_CAP_REACHED == _newState ||
        SaleState.FAILED == _newState ||
        SaleState.SUCCEEDED == _newState
      );
    } else if (SaleState.SOFT_CAP_REACHED == state) {
      assert(
        SaleState.PAUSED == _newState ||
        SaleState.SUCCEEDED == _newState
      );
    } else if (SaleState.PAUSED == state) {
      assert(SaleState.ACTIVE == _newState || SaleState.FAILED == _newState);
    } else {
      assert(false);
    }

    state = _newState;
    emit StateChanged(state);

    if (SaleState.SOFT_CAP_REACHED == state) {
      onSoftCapReached();
    } else if (SaleState.SUCCEEDED == state) {
      onSuccess();
    } else if (SaleState.FAILED == state) {
      onFailure();
    }
  }

  function onSoftCapReached() private {
    wallet.changeState(BablosCrowdsaleWalletInterface.State.SUCCEEDED);
  }

  function onSuccess() private {
    // burn all remaining tokens
    token.burn(token.balanceOf(address(this)));
    token.thaw();
    wallet.unholdTeamTokens();
    wallet.detachController();
  }

  function onFailure() private {
    // allow clients to get their ether back
    wallet.changeState(BablosCrowdsaleWalletInterface.State.REFUNDING);
    wallet.unholdTeamTokens();
    wallet.detachController();
    uint tokens = token.balanceOf(address(this));
    token.approve(owner, tokens);
  }

  /// @dev to be overridden in tests
  function getTime() internal view returns (uint) {
    // solium-disable-next-line security/no-block-members
    return now;
  }

}