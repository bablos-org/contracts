pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

import "./BablosTokenInterface.sol";
import "./BasicDividendToken.sol";
import "./UpgradeableToken.sol";

contract BablosToken is BablosTokenInterface, BasicDividendToken, UpgradeableToken, DetailedERC20, BurnableToken, Pausable {
  using SafeMath for uint256;

  /// @notice set of sale account which can freeze tokens
  address public sale;

  /// @notice when true - all tokens are frozen and only sales or contract owner can move their tokens
  ///         when false - all tokens are unfrozen and can be moved by their owners
  bool public frozen = true;

  /// @dev makes transfer possible if tokens are unfrozen OR if the caller is a sale account
  modifier saleOrUnfrozen() {
    require((frozen == false) || msg.sender == sale || msg.sender == owner);
    _;
  }

  /// @dev allowance to call method only if the caller is a sale account
  modifier onlySale() {
    require(msg.sender == sale);
    _;
  }

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) 
      public 
      UpgradeableToken(msg.sender)
      DetailedERC20(_name, _symbol, _decimals) 
  {
    totalSupply_ = _totalSupply;
    balances[msg.sender] = totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value)
      public 
      whenNotPaused 
      saleOrUnfrozen
      returns (bool) 
  {
    super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value)
      public
      whenNotPaused
      saleOrUnfrozen
      returns (bool) 
  {
    super.transferFrom(_from, _to, _value);
  }

  function setSale(address _sale) public onlyOwner {
    frozen = true;
    sale = _sale;
  }

  /// @notice Make transfer of tokens available to everyone
  function thaw() external onlySale {
    frozen = false;
  }
}