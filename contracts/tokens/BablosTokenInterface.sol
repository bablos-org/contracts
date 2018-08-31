pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract BablosTokenInterface is ERC20 {
  bool public frozen;
  function burn(uint256 _value) public;
  function setSale(address _sale) public;
  function thaw() external;
}