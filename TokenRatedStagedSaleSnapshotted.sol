pragma solidity ^0.4.11;

import './BaseRatedStagedTokenSale.sol';
import './TokenSnapshotted.sol';
import './PullPayment.sol';

/**
	ERC20 Token extended with token<->ethereum exchange
*/
contract TokenRatedStagedSaleSnapshotted is TokenSnapshotted, PullPayment, BaseRatedStagedTokenSale {
	uint256 price;
	bool isSaling;

	event PriceChanged(uint256 _oldPrice, uint256 _newPrice);

	/**
		@dev constructor

		@param _initialAmount how much of tokens at start
		@param _name          token name
		@param _symbol        token symbol
		@param _decimals      decimals, 10^decimals represents one token.
		@param _price         price for one token.
	*/
	function TokenRatedStagedSaleSnapshotted(uint256 _initialAmount, string _name, string _symbol, uint8 _decimals, uint256 _price)
		BaseRatedStagedTokenSale(_decimals)
		TokenSnapshotted(_initialAmount, _name, _symbol, _decimals)
	{
		_setPrice(_price);
	}

	function () public payable {
		sale();
	}

	function sale() public payable {
		assert(!isSaling);
		isSaling = true;
		uint256 tokens = _sale();
		while (tokens > 0) {
			assert(currentStage != 0);
			if (stages[currentStage].amount > tokens) {
				stages[currentStage].amount -= tokens;
				tokens = 0;
			} else {
				tokens -= stages[currentStage].amount;
				stages[currentStage].amount = 0;
				currentStage = _getNextStage(currentStage);
			}
		}
		isSaling = false;
	}

	function _getAvailableTokens()
		constant internal returns (uint256)
	{
		return _getBalance(owner);
	}

	function _getPrice()
		internal
		constant
		returns (uint256)
	{
		return price;
	}

	function _setPrice(uint256 _price)
		internal
	{
		assert(_price != 0);
		PriceChanged(price, _price);
		price = _price;
	}

	function getCurrentStage()
		constant external returns (uint256)
	{
		return currentStage;
	}

	function getTokensAvailableForStage(uint256 _stage)
		constant external returns (uint256)
	{
		return _getTokensAvailableForStage(_stage);
	}

	function setPrice(uint256 _price)
		public
		nonContractAdminOnly
		onlyPayloadSize(32)
	{
		_setPrice(_price);
	}

	function getStageTokenPrice(uint256 _stage)
		constant external returns (uint256)
	{
		return _getStageTokenPrice(_stage);
	}

	function addStage(uint256 _amount, uint256 _priceRate)
		external
		adminOnly
		onlyPayloadSize(64)
	{
		assert(!isSaling);
		_addStage(_amount, _priceRate);
	}

	function removeStage(uint256 _key)
		external
		adminOnly
		onlyPayloadSize(32)
	{
		assert(!isSaling);
		_removeStage(_key);
	}

	function getPrevStage(uint256 _stage)
		constant external returns (uint256)
	{
		return _getPrevStage(_stage);
	}

	function getNextStage(uint256 _stage)
		constant external returns (uint256)
	{
		return _getNextStage(_stage);
	}
}