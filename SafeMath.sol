pragma solidity ^0.4.10;

/*
    Overflow protected math functions
*/
contract SafeMath {
  /**
    constructor
  */
  function SafeMath() {
  }

  /**
    @dev returns the sum of _x and _y, carry is bool

    @param _x     value 1
    @param _y     value 2
    @param _subc  subcarry

    @return (sum, c)
  */
  function add(uint256 _x, uint256 _y, uint256 _subc) internal returns (uint256, uint256) {
    uint256 z = _x + _y + _subc;
    return (z, z<_x?1:0);
  }

  /**
    @dev returns the sum of _x and _y, asserts if the calculation overflows

    @param _x   value 1
    @param _y   value 2

    @return sum
  */
  function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
    uint256 z;
    uint256 c;
    (z, c) = add(_x, _y, 0);
    assert(c==0);
    return z;
  }

  /**
    @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

    @param _x   minuend
    @param _y   subtrahend

    @return difference
  */
  function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
    assert(_x >= _y);
    return _x - _y;
  }

  /**
    @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

    @param _x   factor 1
    @param _y   factor 2

    @return product
  */
  function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
    uint256 z = _x * _y;
    assert(_x == 0 || z / _x == _y);
    return z;
  }

  /**
    @dev returns the product of multiplying _x by _y, higher part last, increased by _subc

    @param _x     factor 1
    @param _y     factor 2
    @param _subc  subcarry

    @return (productLow, productHigh)
  */
  function mul(uint256 _x, uint256 _y, uint256 _subc) internal returns (uint256, uint256) {
    uint256 e = 2 ** 128;
    uint256 x0y0 = (_x % e) * (_y % e) + (_subc % e);
    uint256 x1y0 = (_x / e) * (_y % e) + (_subc / e);
    uint256 x0y1 = (_x % e) * (_y / e);
    uint256 x1y1 = (_x / e) * (_y / e);
    (x1y0, x0y1) = add(x1y0, x0y1, x0y0/e);
    return ((x0y0 % e) + ((x1y0 % e) * e), x0y1 * e + x1y1 + x1y0 / e);
  }

  /**
    @dev returns the product of multiplying _x by _y and
    shifting result to the right by 128 bit, asserts if the calculation overflows

    @param _x   factor 1
    @param _y   factor 2

    @return product
  */
  function safeMulF128(uint256 _x, uint256 _y) internal returns (uint256) {
    uint256 e = 2 ** 128;
    uint256 p0;
    uint256 p1;
    (p0, p1) = mul(_x, _y, 0);
    assert(p1<e);
    return p1 * e + p0 / e;
  }

  /**
    @dev returns the product of multiplying _x by _z divided by _y, asserts if the calculation overflows
  */
  function safeDivMul(uint256 _x, uint256 _y, uint256 _z) internal returns (uint256) {
    return safeMul(_x, _z)/_y;
  }

  /**
    @dev returns _x raised to the power _y, asserts if the calculation overflows
  */
  function safePow(uint256 _x, uint8 _y) internal returns (uint256) {
    uint256 r = 1;
    while (_y > 0) {
      if ((_y & 1) == 0) {
        _x = safeMul(_x, _x);
        _y = _y >> 1;
      } else {
        --_y;
        r = safeMul(r, _x);
      }
    }
    return r;
  }

}
