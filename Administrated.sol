pragma solidity ^0.4.10;
import './IAdministrated.sol';
import './Owned.sol';
import './AddressRingManager.sol';

/*
  Provides support and utilities for contract ownership
*/
contract Administrated is IAdministrated, Owned, AddressRingManager {
  AddressRing adminsRing;
  AddressRing locksRing;

  /**
    @dev constructor
  */
  function Administrated()
    Owned()
  {
    _initializeAddressRing(adminsRing);
    _initializeAddressRing(locksRing);
  }

  // allows execution by the admin only
  modifier adminOnly {
    assert(msg.sender == owner || isAdmin(msg.sender));
    _;
  }

  modifier nonContractAdminOnly {
    assert(msg.sender == owner || (isAdmin(msg.sender) && !_isContract(msg.sender)));
    _;
  }

  function _isContract(address addr) internal returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  function lock()
    public
    adminOnly
  {
    _insertToAddressRing(locksRing, msg.sender);
  }

  function unlock()
    public
  {
    unlockAnother(msg.sender);
  }

  function unlockAll()
    public
    adminOnly
  {
    address iter = _getFromAddressRing(locksRing, 0).iterNext;
    while (iter != 0) {
      address next = _getFromAddressRing(locksRing, iter).iterNext;
      if (msg.sender == owner || _isContract(iter)) _removeFromAddressRing(locksRing, iter);
      iter = next;
    }
  }

  function unlockAnother(address _address) public adminOnly {
    require(
      _address == owner ||
      _address == msg.sender ||
      (
        (_isContract(_address) || !_doesAddressRingContain(adminsRing, _address)) &&
        !_isContract(msg.sender)));
    _removeFromAddressRing(locksRing, msg.sender);
  }

  function isLocked() public constant returns (bool) {
    return !_isAddressRingEmpty(locksRing);
  }

  // checks contract is not locked
  modifier unlocked() {
    require(!isLocked());
    _;
  }
  // checks contract is locked
  modifier locked() {
    require(isLocked());
    _;
  }

  function getOwner()
    public
    constant
    returns (address)
  {
    return owner;
  }

  function grantAdmin(address _address)
    public ownerOnly
  {
    _insertToAddressRing(adminsRing, _address);
  }

  function isAdmin(address _address)
    public constant returns (bool)
  {
    return (owner == _address) || _doesAddressRingContain(adminsRing, _address);
  }

  function revokeAdmin(address _address)
    public ownerOnly
  {
    _removeFromAddressRing(adminsRing, _address);
  }

  function getPrevAdmin(address _address)
    public constant returns (address)
  {
    return _getFromAddressRing(adminsRing, _address).iterPrev;
  }
  function getNextAdmin(address _address)
    public constant returns (address)
  {
    return _getFromAddressRing(adminsRing, _address).iterNext;
  }

  function getPrevLock(address _address)
    public constant returns (address)
  {
    return _getFromAddressRing(locksRing, _address).iterPrev;
  }
  function getNextLock(address _address)
    public constant returns (address)
  {
    return _getFromAddressRing(locksRing, _address).iterNext;
  }

}