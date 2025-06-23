// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibAppStorage {
    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    struct Market {
        bool isListed;
        uint8 decimals;
        uint256 reserveFactor;
        uint256 collateralFactor;
        bool canBorrow;
        bool canCollateralize;
        uint256 borrowIndex;
        uint256 supplyIndex;
    }

    struct AppStorage {
        // User balances
        mapping(address => mapping(address => uint256)) userDeposits;
        mapping(address => mapping(address => uint256)) userBorrows;
        
        // Market data
        mapping(address => Market) markets;
        mapping(address => uint256) totalDeposits;
        mapping(address => uint256) totalBorrows;
        
        // Interest rates
        mapping(address => uint256) borrowRates;
        mapping(address => uint256) supplyRates;
        mapping(address => uint256) lastUpdateTimestamp;
        
        // Price feeds
        mapping(address => address) priceFeeds;
        
        // Protocol parameters
        uint256 liquidationIncentive;
        uint256 reserveFactor;
        address treasury;
    }

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}