// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SpreadMonitor} from "../src/SpreadMonitor.sol";

contract SpreadMonitorTest is Test {
    SpreadMonitor public monitor;
    address public owner;
    address public user;

    // 在測試合約內重新宣告，讓 vm.expectEmit 可以比對
    event SpreadAlert(address indexed user, bool triggered);

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        monitor = new SpreadMonitor();
    }

    // 1. setStrategy 設定後 isStrategyActive 回傳 true
    function test_setStrategy_activatesStrategy() public {
        vm.prank(user);
        monitor.setStrategy(saddress(address(0x1)), suint256(100));
        assertTrue(monitor.isStrategyActive(user));
    }

    // 2. checkSpread 低於閾值時 emit SpreadAlert(user, false)
    function test_checkSpread_belowThreshold_emitsFalse() public {
        vm.startPrank(user);
        monitor.setStrategy(saddress(address(0x1)), suint256(80));

        vm.expectEmit(true, false, false, true, address(monitor));
        emit SpreadAlert(user, false);
        monitor.checkSpread(suint256(60));
        vm.stopPrank();
    }

    // 3. checkSpread 高於等於閾值時 emit SpreadAlert(user, true)
    function test_checkSpread_atOrAboveThreshold_emitsTrue() public {
        vm.startPrank(user);
        monitor.setStrategy(saddress(address(0x1)), suint256(80));

        vm.expectEmit(true, false, false, true, address(monitor));
        emit SpreadAlert(user, true);
        monitor.checkSpread(suint256(90));
        vm.stopPrank();
    }

    // 4. deactivate 後 isStrategyActive 回傳 false（onlyOwner）
    function test_deactivate_owner_deactivatesStrategy() public {
        vm.prank(user);
        monitor.setStrategy(saddress(address(0x1)), suint256(100));

        // 測試合約本身就是 owner，直接呼叫
        monitor.deactivate(user);
        assertFalse(monitor.isStrategyActive(user));
    }

    // 5. 非 owner 呼叫 deactivate 應 revert
    function test_deactivate_nonOwner_reverts() public {
        vm.prank(user);
        monitor.setStrategy(saddress(address(0x1)), suint256(100));

        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Not owner"));
        monitor.deactivate(user);
    }
}
