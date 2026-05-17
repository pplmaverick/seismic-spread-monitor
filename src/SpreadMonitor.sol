// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SpreadMonitor {
    address public owner;

    struct Strategy {
        saddress pair;      // 私密：監控的交易對
        suint256 threshold; // 私密：觸發閾值
        bool isActive;      // 公開：策略是否啟動
    }

    mapping(address => Strategy) private strategies;

    event SpreadAlert(address indexed user, bool triggered);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 用戶設定自己的策略（pair 和 threshold 對外不可見）
    function setStrategy(saddress pair, suint256 threshold) external {
        strategies[msg.sender] = Strategy({
            pair: pair,
            threshold: threshold,
            isActive: true
        });
    }

    // signed getter：只有策略擁有者能讀取自己的閾值（cast 後回傳，呼叫者即擁有者）
    function getMyThreshold() external view returns (uint256) {
        require(strategies[msg.sender].isActive, "No active strategy");
        return uint256(strategies[msg.sender].threshold);
    }

    // 用戶傳入當前價差（shielded），合約與閾值比較後 emit 事件
    function checkSpread(suint256 currentSpread) external {
        Strategy storage s = strategies[msg.sender];
        require(s.isActive, "No active strategy");
        bool triggered = bool(currentSpread >= s.threshold); // sbool → bool
        emit SpreadAlert(msg.sender, triggered);
    }

    // 查詢任意用戶的策略啟動狀態（公開資訊）
    function isStrategyActive(address user) external view returns (bool) {
        return strategies[user].isActive;
    }

    // owner 停用任意用戶的策略
    function deactivate(address user) external onlyOwner {
        require(strategies[user].isActive, "Strategy already inactive");
        strategies[user].isActive = false;
    }
}
