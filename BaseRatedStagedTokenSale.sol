pragma solidity ^0.4.0;

import './BaseStagedTokenSale.sol';

/**
	Applies price factor per stage, each factor is actually fixedpoint 128.128 number.
*/
contract BaseRatedStagedTokenSale is BaseStagedTokenSale {
	uint256 denumerator;
	struct Stage {
		uint256 amount;
		uint256 priceRate;
	}
	mapping (uint256 => Stage) stages;
	Uint256Ring stagesRing;
	uint256 currentStage;

	function BaseRatedStagedTokenSale(uint8 _decimals)
		BaseStagedTokenSale(_decimals)
	{
		_initializeUint256Ring(stagesRing);
	}

	function _getPrice()
		internal
		constant
		returns (uint256)
	{
		throw;
	}

	function _addStage(uint256 _amount, uint256 _priceRate)
		internal
	{
		uint256 newStageId = block.timestamp;
		assert(!_doesUint256RingContain(stagesRing, newStageId));
		_insertToUint256Ring(stagesRing, newStageId);
		stages[newStageId] = Stage({amount: _amount, priceRate: _priceRate});
		if (currentStage == 0) {
			currentStage = newStageId;
		}
	}

	function _removeStage(uint256 _key)
		internal
	{
		if (currentStage == _key) currentStage = _getNextStage(currentStage);
		_removeFromUint256Ring(stagesRing, _key);
	}

	function _getCurrentStage()
		constant internal returns (uint256)
	{
		return currentStage;
	}

	function _getPrevStage(uint256 _stage)
		constant internal returns (uint256)
	{
		return _getFromUint256Ring(stagesRing, _stage).iterPrev;
	}

	function _getNextStage(uint256 _stage)
		constant internal returns (uint256)
	{
		return _getFromUint256Ring(stagesRing, _stage).iterNext;
	}

	function _getTokensAvailableForStage(uint256 _stage)
		constant internal returns (uint256)
	{
		return stages[_stage].amount;
	}

	function _getStageTokenPrice(uint256 _stage)
		constant internal returns (uint256)
	{
		return safeMulF128(_getPrice(), stages[_stage].priceRate);
	}

}
