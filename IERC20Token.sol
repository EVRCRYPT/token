pragma solidity ^0.4.10;
import './IBalanceChecker.sol';

/*
  ERC20 Standard Token interface
*/
contract IERC20Token is IBalanceChecker{
  // these functions aren't abstract since the compiler emits automatically generated getter functions as external
  function name() public constant returns (string name) { name; }
  function symbol() public constant returns (string symbol) { symbol; }
  function decimals() public constant returns (uint8 decimals) { decimals; }
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

  function transfer(address _to, uint256 _value) public payable returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool success);
  function approve(address _spender, uint256 _value) public payable returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}