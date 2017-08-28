pragma solidity ^0.4.10;

import './Base.sol';
import './Owned.sol';


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract BasePullPayment is Base {
	mapping(address => uint256) internal payments;
	uint256 public totalPayments;
	AddressRing paymentsRing;

	function BasePullPayment() payable {
		_initializeAddressRing(paymentsRing);
	}

	/**
	* @dev Called by the payer to store the sent amount as credit to be pulled.
	* @param dest The destination address of the funds.
	* @param amount The amount to transfer.
	*/
	function _asyncSend(address dest, uint256 amount) internal {
		if (!_doesAddressRingContain(paymentsRing, dest)) {
			_insertToAddressRing(paymentsRing, dest);
		}
		payments[dest] = safeAdd(payments[dest], amount);
		totalPayments = safeAdd(totalPayments, amount);
	}

	/**
	* @dev withdraw accumulated balance, called by payee.
	*/
	function withdrawPayments()
		public
		payable
	{
		address payee = msg.sender;
		uint256 payment = payments[payee];

		require(payment != 0);
		require(this.balance >= payment);

		totalPayments = safeSub(totalPayments, payment);
		_clearPayment(payee);

		payee.transfer(payment);
	}

	// Unsafe, never call directly from outside
	function _clearPayment(address _whom)
		internal
	{
		delete payments[_whom];
		_removeFromAddressRing(paymentsRing, _whom);
	}
}