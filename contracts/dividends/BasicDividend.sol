pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ReentrancyGuard.sol";

import "./DividendInterface.sol";

contract BasicDividend is DividendInterface, ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  event Dividends(uint256 amount);
  event DividendsClaimed(address claimer, uint256 amount);

  uint256 public totalDividends;
  mapping (address => uint256) public lastDividends;
  mapping (address => uint256) public unclaimedDividends;
  mapping (address => uint256) public claimedDividends;
  ERC20 public token;

  modifier onlyToken() {
    require(msg.sender == address(token));
    _;
  }

  constructor(ERC20 _token) public {
    token = _token;
  }

  /**
   * @dev fallback payment function
   */
  function () external payable {
    putProfit();
  }

  /**
   * @dev on every ether transaction totalDividends is incremented by amount
   */
  function putProfit() public nonReentrant onlyOwner payable {
    totalDividends = totalDividends.add(msg.value);
    emit Dividends(msg.value);
  }

  /**
  * @dev Gets the unclaimed dividends balance of the specified address.
  * @param _account The address to query the the dividends balance of.
  * @return An uint256 representing the amount of dividends owned by the passed address.
  */
  function dividendBalanceOf(address _account) public view returns (uint256) {
    uint256 accountBalance = token.balanceOf(_account);
    uint256 totalSupply = token.totalSupply();
    uint256 newDividends = totalDividends.sub(lastDividends[_account]);
    uint256 product = accountBalance.mul(newDividends);
    return product.div(totalSupply) + unclaimedDividends[_account];
  }

  function claimedDividendsOf(address _account) public view returns (uint256) {
    return claimedDividends[_account];
  }

  function hasDividends() public view returns (bool) {
    return totalDividends > 0 && address(this).balance > 0;
  }

  /**
  * @dev claim dividends
  */
  function claimDividends() public nonReentrant returns (uint256) {
    require(address(this).balance > 0);
    uint256 dividends = dividendBalanceOf(msg.sender);
    require(dividends > 0);
    lastDividends[msg.sender] = totalDividends;
    unclaimedDividends[msg.sender] = 0;
    claimedDividends[msg.sender] = claimedDividends[msg.sender].add(dividends);
    msg.sender.transfer(dividends);
    emit DividendsClaimed(msg.sender, dividends);
    return dividends;
  }

  function saveUnclaimedDividends(address _account) public onlyToken {
    if (totalDividends > lastDividends[_account]) {
      unclaimedDividends[_account] = dividendBalanceOf(_account);
      lastDividends[_account] = totalDividends;
    }
  }
}