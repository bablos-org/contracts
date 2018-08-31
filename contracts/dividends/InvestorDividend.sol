pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ReentrancyGuard.sol";

import "../tokens/BablosTokenInterface.sol";

contract InvestorDividend is ReentrancyGuard, Ownable {

  enum RequestState { INIT, APPROVED, REJECTED }

  struct InvestorRequest {
    uint tokens;
    string data;
    uint state;
  }

  BablosTokenInterface public token;
  uint public minimumAmount;
  string public publicKey;

  mapping(address => InvestorRequest) public request;

  constructor(BablosTokenInterface _token, uint _minimumAmount) public {
    token = _token;
    minimumAmount = _minimumAmount;
  }

  function setPublicKey(string _publicKey) external onlyOwner {
    publicKey = _publicKey;
  }

  function createRequest(string _data) external nonReentrant {
    require(!token.frozen());
    uint tokens = token.allowance(msg.sender, address(this));
    require(tokens >= minimumAmount);
    InvestorRequest storage req = request[msg.sender];
    require(req.tokens == 0);
    token.transferFrom(msg.sender, address(this), tokens);
    
    req.tokens = tokens;
    req.data = _data;
    req.state = uint(RequestState.INIT);
  }

  function approveRequest(address _investor) external onlyOwner {
    require(!token.frozen());
    InvestorRequest storage req = request[_investor];
    require(req.tokens >= minimumAmount);
    require(token.balanceOf(address(this)) >= req.tokens);
    req.state = uint(RequestState.APPROVED);
    token.burn(req.tokens);
  }

  function rejectRequest(address _investor) external onlyOwner {
    require(!token.frozen());
    InvestorRequest storage req = request[_investor];
    require(req.tokens >= minimumAmount);
    require(token.balanceOf(address(this)) >= req.tokens);
    uint tokens = req.tokens;
    req.tokens = 0;
    req.state = uint(RequestState.REJECTED);
    token.transfer(_investor, tokens);
  }

}