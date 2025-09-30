// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ShahSwap - A custom Ethereum-based swap contract for SHAH ↔ ETH
/// @author You
/// @notice Supports two-way swaps with a 0.3% fee, owner control, and real ETH handling

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ShahSwap {
    address public owner;
    address public shahToken;
    address public treasury;

    uint256 public exchangeRate; // ETH (in wei) per 1 SHAH
    uint256 public feeBasisPoints; // e.g. 30 = 0.3%

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    event SwappedShahForEth(address indexed user, uint256 shahIn, uint256 ethOut, uint256 fee);
    event SwappedEthForShah(address indexed user, uint256 ethIn, uint256 shahOut, uint256 fee);
    event ExchangeRateUpdated(uint256 newRate);
    event FeeUpdated(uint256 newFeeBps);

    constructor(address _shahToken, address _treasury) {
        owner = msg.sender;
        shahToken = _shahToken;
        treasury = _treasury;

        // Default settings
        exchangeRate = 1381900000000000; // 0.0013819 ETH per SHAH (in wei)
        feeBasisPoints = 30; // 0.3%
    }

    // 🔁 Swap SHAH → ETH
    function swapShahForEth(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be > 0");

        uint256 fee = (amountIn * feeBasisPoints) / 10000;
        uint256 netShah = amountIn - fee;

        uint256 ethOut = netShah * exchangeRate;
        require(address(this).balance >= ethOut, "Insufficient ETH in contract");

        // Transfer SHAH from user
        require(IERC20(shahToken).transferFrom(msg.sender, treasury, netShah), "SHAH transfer failed");
        if (fee > 0) {
            require(IERC20(shahToken).transferFrom(msg.sender, treasury, fee), "Fee transfer failed");
        }

        // Transfer ETH to user
        payable(msg.sender).transfer(ethOut);
        emit SwappedShahForEth(msg.sender, amountIn, ethOut, fee);
    }

    // 🔁 Swap ETH → SHAH
    function swapEthForShah() external payable {
        require(msg.value > 0, "Must send ETH");

        uint256 rawShah = msg.value / exchangeRate;
        uint256 fee = (rawShah * feeBasisPoints) / 10000;
        uint256 netShah = rawShah - fee;

        require(IERC20(shahToken).balanceOf(address(this)) >= rawShah, "Not enough SHAH in pool");

        // Transfer SHAH to user
        require(IERC20(shahToken).transfer(msg.sender, netShah), "SHAH payout failed");

        // Transfer fee to treasury
        if (fee > 0) {
            require(IERC20(shahToken).transfer(treasury, fee), "SHAH fee failed");
        }

        emit SwappedEthForShah(msg.sender, msg.value, netShah, fee);
    }

    // Admin Controls
    function setExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Invalid rate");
        exchangeRate = newRate;
        emit ExchangeRateUpdated(newRate);
    }

    function setFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 500, "Fee too high (max 5%)");
        feeBasisPoints = newFeeBps;
        emit FeeUpdated(newFeeBps);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        treasury = newTreasury;
    }

    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawSHAH(uint256 amount) external onlyOwner {
        require(IERC20(shahToken).transfer(owner, amount), "Withdraw failed");
    }

    receive() external payable {}
}

