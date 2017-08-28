pragma solidity ^0.4.10;

contract Safe {
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  } 
}
