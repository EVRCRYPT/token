pragma solidity ^0.4.10;
import './IOwned.sol';

/*
  Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
  address public owner;
  address public newOwner;

  event OwnerUpdate(address _prevOwner, address _newOwner);

  /**
    @dev constructor
  */
  function Owned() {
    owner = msg.sender;
  }

  // allows execution by the owner only
  modifier ownerOnly {
    assert(msg.sender == owner);
    _;
  }

  // allows execution by the admin only
  modifier adminOnly {
    assert(msg.sender == owner);
    _;
  }

  /**
    @dev allows transferring the contract ownership
    the new owner still need to accept the transfer
    can only be called by the contract owner

   @param _newOwner    new contract owner
  */
  function transferOwnership(address _newOwner) public ownerOnly {
    assert(_newOwner != owner);
    newOwner = _newOwner;
  }

  /**
    @dev used by a new owner to accept an ownership transfer
  */
  function acceptOwnership() public {
    assert(msg.sender == newOwner);
    OwnerUpdate(owner, newOwner);
    owner = newOwner;
    newOwner = 0x0;
  }

  function kill() {
    assert(msg.sender == owner);
    selfdestruct(owner);
  }
}
