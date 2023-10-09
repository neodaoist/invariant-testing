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

        targetContract(address(handler));
    }

    function invariant_conservationOfETH() public {
        assertEq(handler.ETH_SUPPLY(), address(handler).balance + weth.totalSupply());
    }

    function invariant_solvencyDeposits() public {
        assertEq(address(weth).balance, handler.ghost_depositSum() - handler.ghost_withdrawSum());
    }

    // function invariant_solvencyBalances() public {
    //     assertEq(address(weth).balance, sumOfBalances);
    // }
}
