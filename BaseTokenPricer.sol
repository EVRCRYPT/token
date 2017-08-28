pragma solidity ^0.4.0;

import './Base.sol';


contract BaseTokenPricer is Base {
	uint256 denumerator;

	function BaseTokenPricer(uint8 _decimals)
		payable
	{
		denumerator = safePow(10, _decimals);
	}

	/**
		@dev determines tokens cost

		@return  uint256
	*/
	function _calcEtherForTokens(uint256 _amount, uint256 _price)
		constant internal returns (uint256)
	{
		uint256 r = safeDivMul(_amount, denumerator, _price);
		if (mulmod(_amount, _price, denumerator) != 0) {
			++r;
		}
		return r;
	}


	/**
		@dev determines tokens amount for ether given

		@return  uint256
	*/
	function _calcTokensForEther(uint256 _amount, uint256 _price)
		constant internal returns (uint256)
	{
		uint256 r = safeDivMul(_amount, _price, denumerator);
		return r;
	}
}
