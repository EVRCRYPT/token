pragma solidity ^0.4.0;

import './AddressRingManager.sol';
import './Uint256RingManager.sol';
import './Safe.sol';
import './SafeMath.sol';

contract Base is Safe, SafeMath, Uint256RingManager, AddressRingManager {
}
