pragma solidity ^0.4.10;

/*
    Ring support functions
*/
contract AddressRingManager {
    // 0-th address is used in purpose to store first address in iterNext and last in iterPrev.
    // TODO we can possibly migrate this to XOR-linked list to economy one address of iterPrev and iterNext.
    struct AddressRingNode {
        address iterPrev;
        address iterNext;
    }
    struct AddressRing {
        mapping(address => AddressRingNode) data;
    }

    /**
        constructor
    */
    function AddressRingManager() {
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        assert(_address != 0x0);
        _;
    }

    /**
        @dev returns flag showing if record for _address exists in the _ring

        @param _ring    AddressRing
        @param _address address to check

        @return bool
    */
    function _doesAddressRingContain(AddressRing storage _ring, address _address)
        constant
        internal
        returns(bool)
    {
       return (_getFromAddressRing(_ring, _address).iterPrev != 0) || (_getFromAddressRing(_ring, _address).iterNext != 0) || (_getFromAddressRing(_ring, 0).iterNext == _address);
    }

    /**
        @dev returns flag showing if record for _address exists in the _ring

        @param _ring    AddressRing
        @param _address address to check

        @return bool
    */
    function _getFromAddressRing(AddressRing storage _ring, address _address)
        constant
        internal
        returns(AddressRingNode storage)
    {
       return _ring.data[_address];
    }

    /**
        @dev returns flag showing if the ring is empty

        @param _ring    AddressRing

        @return bool
    */
    function _isAddressRingEmpty(AddressRing storage _ring)
        constant
        internal
        returns(bool)
    {
        return (_getFromAddressRing(_ring, 0).iterPrev == 0) && (_getFromAddressRing(_ring, 0).iterNext == 0);
    }

    /**
        @dev initializes a ring for further use

        @param _ring   AddressRing
    */
    function _initializeAddressRing(AddressRing storage _ring)
        internal
    {
        _ring.data[0] = AddressRingNode(0, 0);
    }

    /**
        @dev inserts new record to the ring

        @param _ring      AddressRing
        @param _address   address to add
    */
    function _insertToAddressRing(AddressRing storage _ring, address _address)
        internal
        validAddress(_address)
    {
        if (_doesAddressRingContain(_ring, _address)) return;
        _ring.data[_address] = AddressRingNode(_ring.data[0].iterPrev, 0);
        _ring.data[_ring.data[0].iterPrev].iterNext = _address;
        _ring.data[0].iterPrev = _address;
    }

    /**
        @dev inserts new record to the ring before given

        @param _ring      AddressRing
        @param _from      address to be next after being inserted one
        @param _address   address to add
    */
    function _insertToAddressRingBefore(AddressRing storage _ring, address _from, address _address)
        internal
        validAddress(_address)
    {
        assert(_doesAddressRingContain(_ring, _from) || (_from == 0));
        if (_doesAddressRingContain(_ring, _address)) return;
        _ring.data[_address] = AddressRingNode(_ring.data[_from].iterPrev, _from);
        _ring.data[_ring.data[_from].iterPrev].iterNext = _address;
        _ring.data[_from].iterPrev = _address;
    }

    /**
        @dev inserts new record to the ring after given

        @param _ring      AddressRing
        @param _from      address to be previous before being inserted one
        @param _address   address to add
    */
    function _insertToAddressRingAfter(AddressRing storage _ring, address _from, address _address)
        internal
        validAddress(_address)
    {
        assert(_doesAddressRingContain(_ring, _from) || (_from == 0));
        if (_doesAddressRingContain(_ring, _address)) return;
        _ring.data[_address] = AddressRingNode(_from, _ring.data[_from].iterNext);
        _ring.data[_ring.data[_from].iterNext].iterPrev = _address;
        _ring.data[_from].iterNext = _address;
    }

    /**
        @dev removes a record from the ring

        @param _ring      AddressRing
        @param _address   address to remove
    */
     function _removeFromAddressRing(AddressRing storage _ring, address _address)
        internal
        validAddress(_address)
        returns (bool)
    {
        if (!_doesAddressRingContain(_ring, _address)) return false;
        _ring.data[_ring.data[_address].iterNext].iterPrev = _ring.data[_address].iterPrev;
        _ring.data[_ring.data[_address].iterPrev].iterNext = _ring.data[_address].iterNext;
        delete _ring.data[_address];
        return true;
    }
}