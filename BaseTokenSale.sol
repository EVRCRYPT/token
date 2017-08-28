pragma solidity ^0.4.10;

import './IOwned.sol';
import './IToken.sol';
import './BaseTokenPricer.sol';
import './PullPayment.sol';

/**
	ERC20 Token extension with sale
*/
contract BaseTokenSale is IToken, Owned, BaseTokenPricer, BasePullPayment
{
	function BaseTokenSale(uint8 _decimals)
		BaseTokenPricer(_decimals)
	{
	}

	function _getPrice()
		internal
		constant
		returns (uint256)
	{
		throw;
	}

	function getPrice()
		public
		constant
		returns (uint256)
	{
		return _getPrice();
	}

	/**
		@dev returns available amount of tokens

		@return  uint256
	*/
	function _getAvailableTokens()
		constant internal returns (uint256)
	{
		return 0;
	}

	/**
		@dev determines tokens amount for ether given and how much should be returned back.

		@return  uint256, uint256
	*/
	function _calcAvailableTokensForEther(uint256 _amount)
		constant internal returns (uint256, uint256)
	{
		uint256 price = _getPrice();
		uint256 r = _calcTokensForEther(_amount, price);
		uint256 available = _getAvailableTokens();
		if (r > available) r = available;
		return (r, safeSub(_amount, _calcEtherForTokens(r, price)));
	}

	function calcAvailableTokensForEther(uint256 _amount)
		constant external returns (uint256, uint256)
	{
		return _calcAvailableTokensForEther(_amount);
	}

	function _distributeIncome(uint256 _amount) internal {
		_asyncSend(owner, _amount);
	}

	function _sale()
		internal
		returns (uint256)
	{
		if (msg.value == 0) return;
		uint256 tokens;
		uint256 remaining;
		uint256 etherSent = safeAdd(msg.value, payments[msg.sender]);
		_clearPayment(msg.sender);
		(tokens, remaining) = _calcAvailableTokensForEther(etherSent);
		assert(tokens > 0);
		_distributeIncome(msg.value-remaining);
		_transfer(owner, msg.sender, tokens);
		if (remaining > 0) {
			_asyncSend(msg.sender, remaining);
		}
		return tokens;
	}
}