// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {WETH9} from "../../src/WETH9.sol";

import {ActorSet, LibActorSet} from "./LibActorSet.sol";

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2} from "forge-std/console2.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    //
    using LibActorSet for ActorSet;

    WETH9 private weth; // CUT

    ActorSet private _actors;
    address private currentActor;
    mapping(bytes32 => uint256) private calls;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    uint256 public ghost_zeroWithdrawals;

    uint256 public constant ETH_SUPPLY = 120_250_000 ether;

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor(WETH9 _weth) {
        weth = _weth;
        deal(address(this), ETH_SUPPLY);
    }

    function deposit(uint256 amount) public createActor countCall("deposit") {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        weth.deposit{value: amount}();

        ghost_depositSum += amount;
    }

    function withdraw(uint256 amount) public createActor countCall("withdraw") {
        amount = bound(amount, 0, weth.balanceOf(currentActor)); // TODO propose fix
        if (amount == 0) ghost_zeroWithdrawals++;

        vm.startPrank(currentActor);
        weth.withdraw(amount);
        _pay(address(this), amount);
        vm.stopPrank();

        ghost_withdrawSum += amount;
    }

    function sendFallback(uint256 amount) public createActor countCall("sendFallback") {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        (bool success,) = address(weth).call{value: amount}("");
        require(success, "sendFallback failed");

        ghost_depositSum += amount;
    }

    receive() external payable {}

    //////

    function actors() external view returns (address[] memory) {
        return _actors.addrs;
    }

    function forEachActor(function(address) external func) public {
        _actors.forEach(func); // TODO propose fix
    }

    function reduceActors(uint256 acc, function(uint256,address) external returns (uint256) func)
        public
        returns (uint256)
    {
        return _actors.reduce(acc, func);
    }

    function callSummary() external view {
        console2.log("Call summary:");
        console2.log("-------------------");
        console2.log("deposit", calls["deposit"]);
        console2.log("withdraw", calls["withdraw"]);
        console2.log("sendFallback", calls["sendFallback"]);

        console2.log("-------------------");
        console2.log("Zero withdrawals:", ghost_zeroWithdrawals);
    }

    //////

    function _pay(address to, uint256 amount) private {
        (bool success,) = to.call{value: amount}("");
        require(success, "pay() failed");
    }
}
