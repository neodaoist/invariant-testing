// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct ActorSet {
    address[] addrs;
    mapping(address => bool) saved;
}

library LibActorSet {
    function add(ActorSet storage s, address addr) internal {
        if (!s.saved[addr]) {
            s.addrs.push(addr);
            s.saved[addr] = true;
        }
    }

    function contains(ActorSet storage s, address addr) internal view returns (bool) {
        return s.saved[addr];
    }

    function count(ActorSet storage s) internal view returns (uint256) {
        return s.addrs.length;
    }

    function forEach(ActorSet storage s, function(address) external func) internal {
        for (uint256 i = 0; i < s.addrs.length; ++i) {
            func(s.addrs[i]);
        }
    }

    function reduce(ActorSet storage s, uint256 acc, function(uint256,address) external returns (uint256) func) internal returns (uint256) {
        for (uint256 i = 0; i < s.addrs.length; ++i) {
            acc = func(acc, s.addrs[i]);
        }
        return acc;
    }
}
