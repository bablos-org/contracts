pragma solidity ^0.4.23;

contract DividendInterface {
  function putProfit() public payable;
  function dividendBalanceOf(address _account) public view returns (uint256);
  function hasDividends() public view returns (bool);
  function claimDividends() public returns (uint256);
  function claimedDividendsOf(address _account) public view returns (uint256);
  function saveUnclaimedDividends(address _account) public;
}