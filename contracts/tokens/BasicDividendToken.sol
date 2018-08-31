pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

import "../dividends/DividendInterface.sol";

contract BasicDividendToken is StandardToken, Ownable {
  using SafeMath for uint256;

  DividendInterface public dividends;

  /**
  * @dev set dividend contract
  * @param _dividends The dividend contract address
  */
  function setDividends(DividendInterface _dividends) public onlyOwner {
    dividends = _dividends;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (dividends != address(0) && dividends.hasDividends()) {
      dividends.saveUnclaimedDividends(msg.sender);
      dividends.saveUnclaimedDividends(_to);
    }

    return super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    if (dividends != address(0) && dividends.hasDividends()) {
      dividends.saveUnclaimedDividends(_from);
      dividends.saveUnclaimedDividends(_to);
    }

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}