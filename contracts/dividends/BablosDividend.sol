pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "./BasicDividend.sol";

contract BablosDividend is BasicDividend {

  constructor(ERC20 _token) public BasicDividend(_token) {

  }

}