// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Test} from "forge-std/Test.sol";
import {Handler} from "./handlers/Handler.sol";

import {WETH9} from "../src/WETH9.sol";

contract WETH9InvariantTest is Test {
    WETH9 private weth;
    Handler private handler;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.sendFallback.selector;

        targetSelector(
            FuzzSelector({
                addr: address(handler),
                selectors: selectors
            })
        );
        targetContract(address(handler));
    }

    function invariant_conservationOfETH() public {
        assertEq(handler.ETH_SUPPLY(), address(handler).balance + weth.totalSupply());
    }

    function invariant_solvencyDeposits() public {
        assertEq(address(weth).balance, handler.ghost_depositSum() - handler.ghost_withdrawSum());
    }

    function invariant_solvencyBalances() public {
        uint256 sumOfBalances = handler.reduceActors(0, this.accumulateBalance);
        assertEq(address(weth).balance, sumOfBalances);
    }

    //////

    function accumulateBalance(uint256 balance, address caller) external view returns (uint256) {
        return balance + weth.balanceOf(caller);
    }
}
