// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibAppStorage} from "../libraries";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract LendingFacet {
    using LibAppStorage for LibAppStorage.AppStorage;
    
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    
    modifier onlyListedMarket(address token) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.markets[token].isListed, "Market not listed");
        _;
    }
    
    function deposit(address token, uint256 amount) external onlyListedMarket(token) {
        require(amount > 0, "Amount must be greater than 0");
        
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        // Update interest before deposit
        _updateInterest(token);
        
        // Transfer tokens from user
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Update user deposits
        s.userDeposits[msg.sender][token] += amount;
        s.totalDeposits[token] += amount;
        
        emit Deposit(msg.sender, token, amount);
    }
    
    function withdraw(address token, uint256 amount) external onlyListedMarket(token) {
        require(amount > 0, "Amount must be greater than 0");
        
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        // Update interest before withdrawal
        _updateInterest(token);
        
        require(s.userDeposits[msg.sender][token] >= amount, "Insufficient balance");
        
        // Check if withdrawal would break collateral requirements
        // (This is a simplified check - in production, you'd need more sophisticated logic)
        require(_checkAccountLiquidity(msg.sender, token, amount), "Insufficient collateral");
        
        // Update balances
        s.userDeposits[msg.sender][token] -= amount;
        s.totalDeposits[token] -= amount;
        
        // Transfer tokens to user
        IERC20(token).transfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, token, amount);
    }
    
    function getSupplyBalance(address user, address token) external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.userDeposits[user][token];
    }
    
    function getTotalSupply(address token) external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalDeposits[token];
    }
    
    function getSupplyAPY(address token) external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.supplyRates[token];
    }
    
    // Internal functions
    function _updateInterest(address token) internal {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
        uint256 currentTimestamp = block.timestamp;
        uint256 deltaTime = currentTimestamp - s.lastUpdateTimestamp[token];
        
        if (deltaTime > 0) {
            // Simple interest calculation (in production, use compound interest)
            uint256 borrowRate = s.borrowRates[token];
            uint256 supplyRate = s.supplyRates[token];
            
            // Update indices
            s.borrowIndex[token] += (borrowRate * deltaTime) / 365 days;
            s.supplyIndex[token] += (supplyRate * deltaTime) / 365 days;
            
            s.lastUpdateTimestamp[token] = currentTimestamp;
        }
    }
    
    function _checkAccountLiquidity(address user, address token, uint256 withdrawAmount) internal view returns (bool) {
        // Simplified liquidity check
        // In production, this would calculate collateral value vs borrow value
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentDeposit = s.userDeposits[user][token];
        return currentDeposit >= withdrawAmount;
    }
}