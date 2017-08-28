pragma solidity ^0.4.10;
import './IOwned.sol';

/*
  Administrated contract interface
*/
contract IAdministrated is IOwned {
  function grantAdmin(address _address) public;
  function isAdmin(address _address) public constant returns (bool);
  function revokeAdmin(address _address) public;
}
