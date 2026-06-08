// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title SpreadMonitor
/// @dev Seismic-based spread monitoring contract. Uses shielded types (saddress, suint256)
///      to keep each user's trading pair and threshold private on-chain.
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

    /// @notice Register or overwrite the caller's spread-monitoring strategy.
    /// @dev Both `pair` and `threshold` are stored as shielded types and are not
    ///      observable by any party other than the caller.
    /// @param pair    The shielded address of the trading pair to monitor.
    /// @param threshold The shielded spread value above which an alert should fire.
    function setStrategy(saddress pair, suint256 threshold) external {
        strategies[msg.sender] = Strategy({
            pair: pair,
            threshold: threshold,
            isActive: true
        });
    }

    /// @notice Return the caller's stored spread threshold.
    /// @dev Reverts if the caller has no active strategy. The shielded value is
    ///      cast to plain uint256 before returning; only the strategy owner can call this.
    /// @return The caller's threshold as a plain uint256.
    function getMyThreshold() external view returns (uint256) {
        require(strategies[msg.sender].isActive, "No active strategy");
        return uint256(strategies[msg.sender].threshold);
    }

    /// @notice Compare a shielded spread value against the caller's threshold and emit an alert.
    /// @dev The comparison is performed entirely within shielded arithmetic; only the
    ///      boolean result (`triggered`) is revealed through the emitted event.
    /// @param currentSpread The caller's current spread observation as a shielded uint256.
    function checkSpread(suint256 currentSpread) external {
        Strategy storage s = strategies[msg.sender];
        require(s.isActive, "No active strategy");
        bool triggered = bool(currentSpread >= s.threshold); // sbool → bool
        emit SpreadAlert(msg.sender, triggered);
    }

    /// @notice Check whether a given user has an active spread-monitoring strategy.
    /// @dev `isActive` is a plain bool stored in the struct and is publicly readable.
    /// @param user The address to query.
    /// @return True if the user's strategy is currently active, false otherwise.
    function isStrategyActive(address user) external view returns (bool) {
        return strategies[user].isActive;
    }

    /// @notice Deactivate a user's strategy. Restricted to the contract owner.
    /// @dev Reverts if the strategy is already inactive to prevent redundant writes.
    /// @param user The address whose strategy should be deactivated.
    function deactivate(address user) external onlyOwner {
        require(strategies[user].isActive, "Strategy already inactive");
        strategies[user].isActive = false;
    }
}
