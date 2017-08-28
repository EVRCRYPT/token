pragma solidity ^0.4.10;

import './Administrated.sol';
import './BasePullPayment.sol';


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment is Administrated, BasePullPayment {
  function PullPayment() payable Administrated() BasePullPayment() {}

  /**
  * @dev get ether balance available.
  */
  function getPayment(address _whom)
    constant
    public
    returns (uint256)
  {
    return payments[_whom];
  }

  /**
  * @dev get previous payee for iteration.
  */
  function getPrevPayee(address _whom)
    constant
    public
    returns (address)
  {
    return _getFromAddressRing(paymentsRing, _whom).iterPrev;
  }

  /**
  * @dev get previous payee for iteration.
  */
  function getNextPayee(address _whom)
    constant
    public
    returns (address)
  {
    return _getFromAddressRing(paymentsRing, _whom).iterNext;
  }

}