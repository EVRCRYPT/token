pragma solidity ^0.4.10;
import './IERC20Token.sol';

/*
  ERC20 Standard Token interface
*/
contract IToken is IERC20Token{
  function _createAccount(address _address) internal returns (bool);
  function _deleteEmptyAccount(address _address) internal returns (bool);
  function _retrieveBalance(address _whom) internal returns (uint256);
  function _increaseBalance(address _whom, uint256 _delta) internal;
  function _decreaseBalance(address _whom, uint256 _delta) internal;

  // Must be implemented as decrease/increase balance pair and calling Transfer event.
  function _transfer(address _from, address _to, uint256 _value) internal returns (bool);
}