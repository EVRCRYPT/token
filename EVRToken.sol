pragma solidity ^0.4.11;

import './TokenRatedStagedSaleSnapshotted.sol';

contract EVRToken is TokenRatedStagedSaleSnapshotted {

	function EVRToken(uint256 _initialAmount, string _name, string _symbol, uint8 _decimals, uint256 _price)
		TokenRatedStagedSaleSnapshotted(_initialAmount, _name, _symbol, _decimals, _price)
	{
	}

	function _distributeIncome(uint256 _amount) internal {
		uint256 share;
		uint256 frac;
		(frac, share) = mul(_amount, 0x028F5C28F5C28F5C28F5C28F5C28F5C28F5C28F5C28F5C28F5C28F5C28F5C28F, 0);
		_asyncSend(0x8e93615E44Be83878eB2e40A8390aC3f71Fc8094, share);
		_asyncSend(owner, safeSub(_amount, share));
	}
}