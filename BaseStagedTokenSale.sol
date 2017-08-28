pragma solidity ^0.4.0;

import './BaseTokenSale.sol';


contract BaseStagedTokenSale is BaseTokenSale{
	function BaseStagedTokenSale(uint8 _decimals)
		BaseTokenSale(_decimals)
	{
	}

	function _getCurrentStage()
		constant
		internal
		returns (uint256)
	{
		throw;
	}

	function _getNextStage(uint256 _stage)
		constant
		internal
		returns (uint256)
	{
		throw;
	}

	function _getTokensAvailableForStage(uint256 _stage)
		constant
		internal
		returns (uint256)
	{
		throw;
	}

	function _getStageTokenPrice(uint256 stage)
		constant
		internal
		returns (uint256)
	{
		throw;
	}

	/**
		@dev determines tokens available amount for ether and stage given and how much ether remains unused.

		@return  (uint256, uint256)
	*/
	function _calcTokensForEtherStage(uint256 _amount, uint256 _stage)
		constant
		internal
		returns (uint256, uint256)
	{
		uint256 price = _getStageTokenPrice(_stage);
		if (price == 0) return (0, _amount);
		uint256 r = _calcTokensForEther(_amount, price);
		uint256 available = _getTokensAvailableForStage(_stage);
		if (r>available) r = available;
		return (r, _amount - _calcEtherForTokens(r, price));
	}

	/**
		@dev determines tokens amount for ether given and how much should be returned back.

		@return  uint256, uint256
	*/
	function _calcAvailableTokensForEther(uint256 _amount)
		constant
		internal
		returns (uint256, uint256)
	{
		uint256 result = 0;
		uint256 amount = _amount;
		uint256 stage = _getCurrentStage();
		uint256 tokensStage = 0;
		uint256 stageTokensAvailable = 0;
		while ((stage != 0) && (tokensStage == stageTokensAvailable)) {
			(tokensStage, amount) = _calcTokensForEtherStage(amount, stage);
			stageTokensAvailable = _getTokensAvailableForStage(stage);
			result += tokensStage;
			stage = _getNextStage(stage);
		}
		return (result, amount);
	}
}
