pragma solidity ^0.4.10;
import './Base.sol';
import './IAccountsIterator.sol';
import './IToken.sol';
import './Administrated.sol';

/*
		Snapshotted token contract
*/
contract TokenSnapshotted is
	IToken, IAccountsIterator, Administrated, Base
{
	uint256 constant BIG_TWO = 2;
	uint8 constant F_BACKGROUND_MAINTENANCE = 0;
	uint8 constant F_BACKGROUND_MAINTENANCE_DELETED_SNAPSHOTS = 1;
	uint8 constant F_BACKGROUND_MAINTENANCE_DELETED_ACCOUNTS = 2;

	struct Snapshot {
		uint256 totalSupply;
		AddressRing balancesRing;
		AddressRing protectedAccountsRing;
		mapping (address => uint256) balances;
		address owner; //0 for current or deleted snapshot.
	}

	string public standard = 'Token 0.1';
	string public name = '';
	string public symbol = '';
	uint8 public decimals = 0;
	mapping (address => AddressRing) internal allowancesRings;
	mapping (address => mapping (address => uint256)) internal allowances;

	mapping (uint256 => Snapshot) snapshots;
	Uint256Ring snapshotsRing;
	Uint256Ring deletedSnapshotsRing;
	AddressRing existingAccountsRing;
	mapping (address => mapping (uint256 => bool)) nonzeroSnapshotsPerAccount;
	mapping (address => uint256) nonzeroSnapshotsPerAccountCount;
	uint256 snapshotBeingMaintainedId;
	uint256 flags;
	mapping (address => uint256) currentSnapshots;
	mapping (address => Uint256Ring) ownedSnapshotsRings;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event AccountCreated(address indexed _owner);
	event AccountDeleted(address indexed _owner);
	event SnapshotCreated(uint256 indexed _snapshot, address indexed _by);
	event SnapshotDeleted(uint256 indexed _snapshot, address indexed _by);
	event SnapshotWiped(uint256 indexed _snapshot, address indexed _by);


	/**
		@dev constructor

		@param _name          token name
		@param _symbol        token symbol
		@param _decimals      decimals, 10^decimals represents one token.
	*/
	function TokenSnapshotted(uint256 _initialAmount, string _name, string _symbol, uint8 _decimals)
		payable Administrated()
	{
		assert((bytes(_name).length > 0) && (bytes(_symbol).length > 0) && (_decimals < 78)); // validate input
		snapshotsRing = Uint256Ring();
		_initializeUint256Ring(snapshotsRing);
		deletedSnapshotsRing = Uint256Ring();
		_initializeUint256Ring(deletedSnapshotsRing);
		existingAccountsRing = AddressRing();
		_initializeAddressRing(existingAccountsRing);
		acquireSnapshot();
		_increaseBalance(owner, _initialAmount);
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		flags = (
			flags |
			(BIG_TWO ** F_BACKGROUND_MAINTENANCE) |
			(BIG_TWO ** F_BACKGROUND_MAINTENANCE_DELETED_SNAPSHOTS) |
			(BIG_TWO ** F_BACKGROUND_MAINTENANCE_DELETED_ACCOUNTS));
	}

	function getFlags()
		public
		constant
		returns (uint256)
	{
		return flags;
	}

	function setFlags(uint256 _flags)
		public
		payable
		adminOnly
	{
		flags = _flags;
	}

	function acquireSnapshot()
		public
		payable
		adminOnly
		returns (uint256)
	{
		_tryMaintain();
		uint256 lssid = _getLastSnapshotId();
		uint256 ssid = block.timestamp;
		assert(!_doesUint256RingContain(snapshotsRing, ssid));
		// snapshots[ssid] = Snapshot({
		//   totalSupply: 0, balancesRing: AddressRing(), protectedAccountsRing: AddressRing(), owner: 0
		// });
		if (lssid != 0) {
			snapshots[lssid].owner = msg.sender;
			snapshots[ssid].totalSupply = snapshots[lssid].totalSupply;
		}
		_insertToUint256Ring(snapshotsRing, ssid);
		_initializeAddressRing(snapshots[ssid].balancesRing);
		_initializeAddressRing(snapshots[ssid].protectedAccountsRing);
		if (currentSnapshots[msg.sender] == 0) {
			ownedSnapshotsRings[msg.sender] = Uint256Ring();
			_initializeUint256Ring(ownedSnapshotsRings[msg.sender]);
		}
		if (lssid != 0) _insertToUint256Ring(ownedSnapshotsRings[msg.sender], lssid);
		currentSnapshots[msg.sender] = lssid;
		return lssid;
	}

	function dropSnapshot(uint256 _ssid)
		public
		payable
		returns (uint256)
	{
		_tryMaintain();
		address owner = snapshots[_ssid].owner;
		assert(owner != 0);
		assert((owner == msg.sender) || (isAdmin(msg.sender)));
		snapshots[_ssid].owner = 0;
		_insertToUint256Ring(deletedSnapshotsRing, _ssid);
		uint256 newssid = currentSnapshots[owner];
		if (currentSnapshots[owner] == _ssid) {
			newssid = _getFromUint256Ring(ownedSnapshotsRings[owner], newssid).iterPrev;
		}
		_removeFromUint256Ring(ownedSnapshotsRings[owner], _ssid);
		if (_isUint256RingEmpty(ownedSnapshotsRings[owner])) {
			delete ownedSnapshotsRings[owner];
			currentSnapshots[owner] = 0;
		} else {
			currentSnapshots[owner] = newssid;
		}
	}

	// TODO extend template engine to support in-file templating,
	// i.e. one function template for next two functions with substitution
	// of Prev/Next into template placeholder.
	function getPrevSnapshot(uint256 _ssid)
		constant
		public
		returns (uint256)
	{
		return _getFromUint256Ring(snapshotsRing, _ssid).iterPrev;
	}
	function getNextSnapshot(uint256 _ssid)
		constant
		public
		returns (uint256)
	{
		return _getFromUint256Ring(snapshotsRing, _ssid).iterNext;
	}

	function getPrevDeletedSnapshot(uint256 _ssid)
		constant
		public
		returns (uint256)
	{
		return _getFromUint256Ring(deletedSnapshotsRing, _ssid).iterPrev;
	}
	function getNextDeletedSnapshot(uint256 _ssid)
		constant
		public
		returns (uint256)
	{
		return _getFromUint256Ring(deletedSnapshotsRing, _ssid).iterNext;
	}

	function getSnapshotOwner(uint256 _ssid)
		constant
		public
		returns (address)
	{
		return snapshots[_ssid].owner;
	}

	function getSnapshotTotalSupply(uint256 _ssid)
		constant
		public
		returns (uint256)
	{
		return snapshots[_ssid].totalSupply;
	}

	function getSnapshotPrevAccount(uint256 _ssid, address _address)
		constant
		public
		returns (address)
	{
		return _getFromAddressRing(snapshots[_ssid].balancesRing, _address).iterPrev;
	}

	function getSnapshotNextAccount(uint256 _ssid, address _address)
		constant
		public
		returns (address)
	{
		return _getFromAddressRing(snapshots[_ssid].balancesRing, _address).iterNext;
	}

	function getSnapshotPrevProtectedAccount(uint256 _ssid, address _address)
		constant
		public
		returns (address)
	{
		return _getFromAddressRing(snapshots[_ssid].protectedAccountsRing, _address).iterPrev;
	}

	function getSnapshotNextProtectedAccount(uint256 _ssid, address _address)
		constant
		public
		returns (address)
	{
		return _getFromAddressRing(snapshots[_ssid].protectedAccountsRing, _address).iterNext;
	}

	// Gives access to current snapshot, which can be customized per address.
	function _getCurrentSnapshotId()
		internal
		constant
		returns (uint256)
	{
		uint256 ssid = currentSnapshots[msg.sender];
		if (ssid != 0) return ssid;
		return _getLastSnapshotId();
	}

	// Gives access to last, the only open for writing snapshot.
	function _getLastSnapshotId()
		internal
		constant
		returns (uint256)
	{
		return _getFromUint256Ring(snapshotsRing, 0).iterPrev;
	}

	function _isLastSnapshotId(uint256 _ssid)
		constant
		internal
		returns (bool)
	{
		return _getFromUint256Ring(snapshotsRing, _ssid).iterNext == 0;
	}

	// Returns id of latest snapshot contains address given.
	// If it is not found, returns 0.
	function _findSnapshotForAccount(address _whom)
		internal
		constant
		returns (uint256)
	{
		uint256 ssid = _getCurrentSnapshotId();
		while (ssid != 0) {
			if (_doesAddressRingContain(snapshots[ssid].balancesRing, _whom)) return ssid;
			if (_doesAddressRingContain(snapshots[ssid].protectedAccountsRing, _whom)) return ssid;
			ssid = _getFromUint256Ring(snapshotsRing, ssid).iterPrev;
		}
		return ssid;
	}

	function _doesAccountExist(address _address)
		constant
		internal
		returns (bool)
	{
		uint256 ssid = _findSnapshotForAccount(_address);
		if (ssid == 0) return false;
		return _doesAddressRingContain(snapshots[ssid].balancesRing, _address);
	}

	function _doesAllowanceExist(address _from, address _to)
		constant
		internal
		returns(bool)
	{
		return _doesAccountExist(_from) && _doesAddressRingContain(allowancesRings[_from], _to);
	}

	// creates account if not exists
	function _createAccount(address _address)
		internal
		returns (bool)
	{
		_retrieveBalance(_address);
		if (_doesAccountExist(_address)) return false;
		uint256 cssid = _getCurrentSnapshotId();
		assert(_isLastSnapshotId(cssid));
		Snapshot css = snapshots[cssid];
		_removeFromAddressRing(css.protectedAccountsRing, _address);
		_insertToAddressRing(css.balancesRing, _address);
		allowancesRings[_address] = AddressRing();
		_initializeAddressRing(allowancesRings[_address]);
		AccountCreated(_address);
		return true;
	}

	// creates allowance if not exists
	function _createAllowance(address _from, address _to)
		internal
		returns (bool)
	{
		_createAccount(_from);
		_insertToAddressRing(allowancesRings[_from], _to);
		return true;
	}

	// checks account has 0 balance and no allowance and deletes it from list
	function _deleteEmptyAccount(address _address)
		internal
		validAddress(_address)
		returns(bool)
	{
		if (_retrieveBalance(_address) != 0 ) return false;
		if (!_doesAccountExist(_address)) return false;
		if (!_isAddressRingEmpty(allowancesRings[_address])) return false;
		uint256 cssid = _getCurrentSnapshotId();
		assert(_isLastSnapshotId(cssid));
		delete allowancesRings[_address];
		Snapshot css = snapshots[cssid];
		_removeFromAddressRing(css.balancesRing, _address);
		_insertToAddressRing(css.protectedAccountsRing, _address);
		AccountDeleted(_address);
		return true;
	}

	function _deleteAllowance(address _from, address _to)
		internal
		returns (bool)
	{
		delete allowances[_from][_to];
		_removeFromAddressRing(allowancesRings[_from], _to);
		return true;
	}

	// checks allowance is 0 and deletes it from list
	function _deleteEmptyAllowance(address _from, address _to)
		internal
		returns (bool)
	{
		if (!_doesAllowanceExist(_from, _to)) return false;
		if (allowances[_from][_to] != 0) return false;
		return _deleteAllowance(_from, _to);
	}

	function _decreaseBalance(address _whom, uint256 _delta)
		internal
	{
		uint256 cssid = _getCurrentSnapshotId();
		assert(_isLastSnapshotId(cssid));
		snapshots[cssid].balances[_whom] = safeSub(_retrieveBalance(_whom), _delta);
		snapshots[cssid].totalSupply = safeSub(snapshots[cssid].totalSupply, _delta);
		if (snapshots[cssid].balances[_whom] == 0) {
			if (nonzeroSnapshotsPerAccount[_whom][cssid]) {
				nonzeroSnapshotsPerAccount[_whom][cssid] = false;
				nonzeroSnapshotsPerAccountCount[_whom] -= 1;
			}
			if (nonzeroSnapshotsPerAccountCount[_whom] == 0) {
				_removeFromAddressRing(existingAccountsRing, _whom);
			} else {
				_insertToAddressRing(snapshots[cssid].protectedAccountsRing, _whom);
			}
		}
		_deleteEmptyAccount(_whom);
	}

	function _increaseBalance(address _whom, uint256 _delta)
		internal
	{
		if (_delta == 0) return;
		_createAccount(_whom);
		uint256 cssid = _getCurrentSnapshotId();
		assert(_isLastSnapshotId(cssid));
		snapshots[cssid].balances[_whom] = safeAdd(_retrieveBalance(_whom), _delta);
		snapshots[cssid].totalSupply = safeAdd(snapshots[cssid].totalSupply, _delta);
		if (!_doesAddressRingContain(existingAccountsRing, _whom)) {
			_insertToAddressRing(existingAccountsRing, _whom);
		}
		if (!nonzeroSnapshotsPerAccount[_whom][cssid]) {
			nonzeroSnapshotsPerAccountCount[_whom] += 1;
		}
	}

	function decreaseBalance(address _whom, uint256 _delta)
		public
		payable
		unlocked
		ownerOnly
		onlyPayloadSize(64)
	{
		_tryMaintain();
		_decreaseBalance(_whom, _delta);
	}

	function increaseBalance(address _whom, uint256 _delta)
		public
		payable
		unlocked
		ownerOnly
		onlyPayloadSize(64)
	{
		_tryMaintain();
		_increaseBalance(_whom, _delta);
	}

	function totalSupply()
		public
		constant
		returns(uint256)
	{
		uint256 cssid = _getCurrentSnapshotId();
		return snapshots[cssid].totalSupply;
	}

	function balanceOf(address _owner)
		public
		constant
		returns(uint256)
	{
		return _getBalance(_owner);
	}

	function _getBalance(address _whom)
		constant
		internal
		returns(uint256)
	{
		if (_doesAccountExist(_whom)) {
			uint256 cssid = _findSnapshotForAccount(_whom);
			return snapshots[cssid].balances[_whom];
		}
		return 0;
	}

	function _retrieveBalance(address _address)
		internal
		returns(uint256)
	{
		uint256 assid = _findSnapshotForAccount(_address);
		// return _getBalance(_address);
		uint256 cssid = _getCurrentSnapshotId();
		if (assid != 0) {
			uint256 balance = snapshots[assid].balances[_address];
			if (assid != cssid) {
				snapshots[cssid].balances[_address] = balance;
				if (balance == 0) {
					_insertToAddressRing(snapshots[cssid].protectedAccountsRing, _address);
				} else {
					// Here we can assume account existed for the current
					// snapshot already, hence allowances aren't snapshotted,
					// so should exist because balance is nonzero in a snapshot.
					_insertToAddressRing(snapshots[cssid].balancesRing, _address);
				}
			}
			return balance;
		}
		return 0;
	}

	// Unsafe idea, so what we can do to make it safier — check we set allowance on no allowance.
	function _setAllowance(address _from, address _to, uint256 _value)
		internal
	{
		bool exists = _doesAllowanceExist(_from, _to);
		if (_value != 0) {
			if (!exists) {
				_createAllowance(_from, _to);
			}
			allowances[_from][_to] = _value;
		} else {
			if (exists) {
				_deleteAllowance(_from, _to);
				_deleteEmptyAccount(_from);
			}
		}
	}


	function allowance(address _from, address _to)
		public
		constant
		returns(uint256)
	{
		return _getAllowance(_from, _to);
	}

	function _getAllowance(address _from, address _to)
		constant
		internal
		returns(uint256)
	{
		if (_doesAllowanceExist(_from, _to))
			return allowances[_from][_to];
		return 0;
	}

	/**
		@dev send coins
		throws on any error rather than return a false flag to minimize user errors

		@param _from    source address
		@param _to      target address
		@param _value   transfer amount

		@return true if the transfer was successful, false if it wasn't
	*/
	function _transfer(address _from, address _to, uint256 _value)
		internal
		returns (bool success)
	{
		_decreaseBalance(_from, _value);
		_increaseBalance(_to, _value);
		Transfer(_from, _to, _value);
		return true;
	}

	function transfer(address _to, uint256 _value)
		public
		payable
		unlocked
		onlyPayloadSize(64)
		returns (bool success)
	{
		_tryMaintain();
		_transfer(msg.sender, _to, _value);
		return true;
	}

	/**
		@dev an account/contract attempts to get the coins
		throws on any error rather then return a false flag to minimize user errors

		@param _from  source address
		@param _to    target address
		@param _value   transfer amount

		@return true if the transfer was successful, false if it wasn't
	*/
	function transferFrom(address _from, address _to, uint256 _value)
		public
		payable
		unlocked
		onlyPayloadSize(96)
		returns (bool success)
	{
		_tryMaintain();
		_setAllowance(_from, msg.sender, safeSub(_getAllowance(_from, msg.sender), _value));
		_decreaseBalance(_from, _value);
		_increaseBalance(_to, _value);
		Transfer(_from, _to, _value);
		return true;
	}

	/**
		@dev allow another account/contract to spend some tokens on your behalf
		throws on any error rather then return a false flag to minimize user errors

		also, to minimize the risk of the approve/transferFrom attack vector
		(see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
		in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

		@param _spender approved address
		@param _value   allowance amount

		@return true if the approval was successful, false if it wasn't
	*/
	function approve(address _spender, uint256 _value)
		public
		payable
		unlocked
		onlyPayloadSize(64)
		returns (bool success)
	{
		_tryMaintain();
		// if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
		assert((_value == 0) || (_getAllowance(msg.sender, _spender) == 0));

		_setAllowance(msg.sender, _spender, _value);
		Approval(msg.sender, _spender, _value);
		return true;
	}

	// TODO extend template engine to support in-file templating,
	// i.e. one function template for next two functions with substitution
	// of Prev/Next into template placeholder.
	function getPrevAccount(address _whom)
		constant
		public
		returns (address)
	{
		uint256 cssid = _getCurrentSnapshotId();
		return _getFromAddressRing(snapshots[cssid].balancesRing, _whom).iterPrev;
	}

	function getNextAccount(address _whom)
		constant
		public
		returns (address)
	{
		uint256 cssid = _getCurrentSnapshotId();
		return _getFromAddressRing(snapshots[cssid].balancesRing, _whom).iterNext;
	}

	function getPrevAllowance(address _from, address _to)
		constant
		public
		returns (address)
	{
		return _getFromAddressRing(allowancesRings[_from], _to).iterPrev;
	}

	function getNextAllowance(address _from, address _to)
		constant
		public
		returns (address)
	{
		return _getFromAddressRing(allowancesRings[_from], _to).iterNext;
	}


	// FIXME this throws, so maintenance does not work.
	function _workOnDeletedSnapshot()
		internal
	{
		if ((flags & (BIG_TWO ** F_BACKGROUND_MAINTENANCE_DELETED_SNAPSHOTS)) == 0) return;
		uint256 dssid = _getFromUint256Ring(deletedSnapshotsRing, 0).iterNext;
		if (dssid == 0) {
			return;
		}
		uint256 nssid = _getFromUint256Ring(snapshotsRing, dssid).iterNext;
		address anAddress = _getFromAddressRing(snapshots[dssid].balancesRing, 0).iterNext;
		if (anAddress == 0) {
			anAddress = _getFromAddressRing(snapshots[dssid].protectedAccountsRing, 0).iterNext;
		}
		if (anAddress == 0) {
			_removeFromUint256Ring(deletedSnapshotsRing, dssid);
			_removeFromUint256Ring(snapshotsRing, dssid);
			SnapshotWiped(dssid, msg.sender);
			return;
		}
		if (
			(!_doesAddressRingContain(snapshots[nssid].balancesRing, anAddress)) &&
			(!_doesAddressRingContain(snapshots[nssid].protectedAccountsRing, anAddress))
		) {
			uint256 balance = snapshots[dssid].balances[anAddress];
			snapshots[nssid].balances[anAddress] = balance;
			if (balance == 0) {
				_insertToAddressRing(snapshots[nssid].protectedAccountsRing, anAddress);
			} else {
				_insertToAddressRing(snapshots[nssid].balancesRing, anAddress);
			}
		}
		_removeFromAddressRing(snapshots[dssid].balancesRing, anAddress);
		_removeFromAddressRing(snapshots[dssid].protectedAccountsRing, anAddress);
		delete snapshots[dssid].balances[anAddress];
	}

	function _workOnDeletedAccounts()
		internal
	{
		if ((flags & (BIG_TWO ** F_BACKGROUND_MAINTENANCE_DELETED_ACCOUNTS)) == 0) return;
		if (snapshotBeingMaintainedId == 0) {
			snapshotBeingMaintainedId = _getFromUint256Ring(snapshotsRing, snapshotBeingMaintainedId).iterNext;
		}
		if (snapshotBeingMaintainedId == 0) return;
		address anAddress = _getFromAddressRing(snapshots[snapshotBeingMaintainedId].protectedAccountsRing, 0).iterNext;
		if (anAddress == 0) {
			snapshotBeingMaintainedId = _getFromUint256Ring(snapshotsRing, snapshotBeingMaintainedId).iterNext;
			return;
		}
		_removeFromAddressRing(snapshots[snapshotBeingMaintainedId].protectedAccountsRing, anAddress);
		if (_doesAddressRingContain(existingAccountsRing, anAddress)) {
			// Placing from beginning to the end of the ring.
			_insertToAddressRing(snapshots[snapshotBeingMaintainedId].protectedAccountsRing, anAddress);
		}
	}

	function _maintain()
		internal
	{
		_workOnDeletedAccounts();
		_workOnDeletedSnapshot();
	}

	function _tryMaintain()
		internal
	{
		if ((flags & (BIG_TWO ** F_BACKGROUND_MAINTENANCE)) == 0) return;
		_maintain();
	}

	function maintain()
		public
		payable
		adminOnly
	{
		_maintain();
	}
}
