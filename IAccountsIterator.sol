pragma solidity ^0.4.10;

/*
    Owned contract interface
*/
contract IAccountsIterator {
  // TODO extend template engine to support in-file templating,
  // i.e. one function template for next two functions with substitution
  // of Prev/Next into template placeholder.
  function getPrevAccount(address _whom) constant public returns (address);
  function getNextAccount(address _whom) constant public returns (address);
}
