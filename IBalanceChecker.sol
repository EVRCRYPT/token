pragma solidity ^0.4.10;

/*
    Balance checker contract interface
*/
contract IBalanceChecker {
  // TODO extend template engine to support in-file templating,
  // i.e. one function template for next two functions with substitution
  // of Prev/Next into template placeholder.
  // These functions aren't abstract since the compiler emits automatically generated getter functions as external
  function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
  function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
}
