pragma solidity ^0.4.23;

import "../tokens/BablosTokenInterface.sol";
import "../oracles/PriceUpdaterInterface.sol";

contract BablosCrowdsaleWalletInterface {
  enum State {
    // gathering funds
    GATHERING,
    // returning funds to investors
    REFUNDING,
    // funds can be pulled by owners
    SUCCEEDED
  }

  event StateChanged(State state);
  event Invested(address indexed investor, PriceUpdaterInterface.Currency currency, uint amount, uint tokensReceived);
  event EtherWithdrawan(address indexed to, uint value);
  event RefundSent(address indexed to, uint value);
  event ControllerRetired(address was);

  /// @dev price updater interface
  PriceUpdaterInterface public priceUpdater;

  /// @notice total amount of investments in currencies
  mapping(uint => uint) public totalInvested;

  /// @notice state of the registry
  State public state = State.GATHERING;

  /// @dev balances of investors in wei
  mapping(address => uint) public weiBalances;

  /// @dev balances of tokens sold to investors
  mapping(address => uint) public tokenBalances;

  /// @dev list of unique investors
  address[] public investors;

  /// @dev token accepted for refunds
  BablosTokenInterface public token;

  /// @dev operations will be controlled by this address
  address public controller;

  /// @dev the team's tokens percent
  uint public teamPercent;

  /// @dev tokens sent to initial PR - they will be substracted, when tokens will be burn
  uint public prTokens;
  
  /// @dev performs only allowed state transitions
  function changeState(State _newState) external;

  /// @dev records an investment
  /// @param _investor who invested
  /// @param _tokenAmount the amount of token bought, calculation is handled by ICO
  /// @param _currency the currency in which investor invested
  /// @param _amount the invested amount
  function invested(address _investor, uint _tokenAmount, PriceUpdaterInterface.Currency _currency, uint _amount) external payable;

  /// @dev get total invested in ETH
  function getTotalInvestedEther() external view returns (uint);

  /// @dev get total invested in EUR
  function getTotalInvestedEur() external view returns (uint);

  /// @notice withdraw `_value` of ether to his address, can be called if crowdsale succeeded
  /// @param _value amount of wei to withdraw
  function withdrawEther(uint _value) external;

  /// @notice owner: send `_value` of tokens to his address, can be called if
  /// crowdsale failed and some of the investors refunded the ether
  /// @param _value amount of token-wei to send
  function withdrawTokens(uint _value) external;

  /// @notice withdraw accumulated balance, called by payee in case crowdsale failed
  /// @dev caller should approve tokens bought during ICO to this contract
  function withdrawPayments() external;

  /// @dev returns investors count
  function getInvestorsCount() external view returns (uint);

  /// @dev ability for controller to step down
  function detachController() external;

  /// @dev unhold holded team's tokens
  function unholdTeamTokens() external;
}