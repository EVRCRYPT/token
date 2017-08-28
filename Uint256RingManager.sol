pragma solidity ^0.4.10;

/*
    Ring support functions
*/
contract Uint256RingManager {
    // 0-th uint256 is used in purpose to store first uint256 in iterNext and last in iterPrev.
    // TODO we can possibly migrate this to XOR-linked list to economy one uint256 of iterPrev and iterNext.
    struct Uint256RingNode {
        uint256 iterPrev;
        uint256 iterNext;
    }
    struct Uint256Ring {
        mapping(uint256 => Uint256RingNode) data;
    }

    /**
        constructor
    */
    function Uint256RingManager() {
    }

    // validates an uint256 - currently only checks that it isn't null
    modifier validUint256(uint256 _uint256) {
        assert(_uint256 != 0x0);
        _;
    }

    /**
        @dev returns flag showing if record for _uint256 exists in the _ring

        @param _ring    Uint256Ring
        @param _uint256 uint256 to check

        @return bool
    */
    function _doesUint256RingContain(Uint256Ring storage _ring, uint256 _uint256)
        constant
        internal
        returns(bool)
    {
       return (_getFromUint256Ring(_ring, _uint256).iterPrev != 0) || (_getFromUint256Ring(_ring, _uint256).iterNext != 0) || (_getFromUint256Ring(_ring, 0).iterNext == _uint256);
    }

    /**
        @dev returns flag showing if record for _uint256 exists in the _ring

        @param _ring    Uint256Ring
        @param _uint256 uint256 to check

        @return bool
    */
    function _getFromUint256Ring(Uint256Ring storage _ring, uint256 _uint256)
        constant
        internal
        returns(Uint256RingNode storage)
    {
       return _ring.data[_uint256];
    }

    /**
        @dev returns flag showing if the ring is empty

        @param _ring    Uint256Ring

        @return bool
    */
    function _isUint256RingEmpty(Uint256Ring storage _ring)
        constant
        internal
        returns(bool)
    {
        return (_getFromUint256Ring(_ring, 0).iterPrev == 0) && (_getFromUint256Ring(_ring, 0).iterNext == 0);
    }

    /**
        @dev initializes a ring for further use

        @param _ring   Uint256Ring
    */
    function _initializeUint256Ring(Uint256Ring storage _ring)
        internal
    {
        _ring.data[0] = Uint256RingNode(0, 0);
    }

    /**
        @dev inserts new record to the ring

        @param _ring      Uint256Ring
        @param _uint256   uint256 to add
    */
    function _insertToUint256Ring(Uint256Ring storage _ring, uint256 _uint256)
        internal
        validUint256(_uint256)
    {
        if (_doesUint256RingContain(_ring, _uint256)) return;
        _ring.data[_uint256] = Uint256RingNode(_ring.data[0].iterPrev, 0);
        _ring.data[_ring.data[0].iterPrev].iterNext = _uint256;
        _ring.data[0].iterPrev = _uint256;
    }

    /**
        @dev inserts new record to the ring before given

        @param _ring      Uint256Ring
        @param _from      uint256 to be next after being inserted one
        @param _uint256   uint256 to add
    */
    function _insertToUint256RingBefore(Uint256Ring storage _ring, uint256 _from, uint256 _uint256)
        internal
        validUint256(_uint256)
    {
        assert(_doesUint256RingContain(_ring, _from) || (_from == 0));
        if (_doesUint256RingContain(_ring, _uint256)) return;
        _ring.data[_uint256] = Uint256RingNode(_ring.data[_from].iterPrev, _from);
        _ring.data[_ring.data[_from].iterPrev].iterNext = _uint256;
        _ring.data[_from].iterPrev = _uint256;
    }

    /**
        @dev inserts new record to the ring after given

        @param _ring      Uint256Ring
        @param _from      uint256 to be previous before being inserted one
        @param _uint256   uint256 to add
    */
    function _insertToUint256RingAfter(Uint256Ring storage _ring, uint256 _from, uint256 _uint256)
        internal
        validUint256(_uint256)
    {
        assert(_doesUint256RingContain(_ring, _from) || (_from == 0));
        if (_doesUint256RingContain(_ring, _uint256)) return;
        _ring.data[_uint256] = Uint256RingNode(_from, _ring.data[_from].iterNext);
        _ring.data[_ring.data[_from].iterNext].iterPrev = _uint256;
        _ring.data[_from].iterNext = _uint256;
    }

    /**
        @dev removes a record from the ring

        @param _ring      Uint256Ring
        @param _uint256   uint256 to remove
    */
     function _removeFromUint256Ring(Uint256Ring storage _ring, uint256 _uint256)
        internal
        validUint256(_uint256)
        returns (bool)
    {
        if (!_doesUint256RingContain(_ring, _uint256)) return false;
        _ring.data[_ring.data[_uint256].iterNext].iterPrev = _ring.data[_uint256].iterPrev;
        _ring.data[_ring.data[_uint256].iterPrev].iterNext = _ring.data[_uint256].iterNext;
        delete _ring.data[_uint256];
        return true;
    }
}