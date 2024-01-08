// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./access/AccessControl.sol";

contract TokenSale is AccessControl {


    event PurchasedTokens (
        address indexed buyer,
        uint256 amount
    );

    uint256 public totalItems;
    address public payToken;
    address private _receiver;
    uint256 public itemValue;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => uint8) public purchasedItems;

    modifier duringSale {
        require(block.timestamp > startTime && block.timestamp < endTime, "Sale not active");
        _;
    }

    modifier afterSale {
        require(block.timestamp > endTime, "Sale not ended");
        _;
    }

    constructor(address receiver, address payToken_, uint256 itemValue_, uint256 startTime_, uint256 endTime_) {
        owner = msg.sender;
        payToken = payToken_;
        itemValue = itemValue_;
        startTime = startTime_;
        endTime = endTime_;
        _receiver = receiver;
    }

    function purchase(uint8 amount, uint256 payAmount) external duringSale whenNotPaused {
        require(amount > 0 && payAmount > 0, "Amount 0");
        require(amount + purchasedItems[msg.sender] <= 100, "Limit reached");
        require(amount * itemValue == payAmount, "Wrong amounts");
        purchasedItems[msg.sender] += amount;
        totalItems += amount;
        bool success = IERC20(payToken).transferFrom(msg.sender, _receiver, payAmount);
        require(success, "Transfer failed");
        emit PurchasedTokens(msg.sender, amount);
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner afterSale {
        bool success = IERC20(tokenAddress).transfer(msg.sender, amount);
        require(success, "Transfer failed");
	}

    function updateSalePeriod(uint256 newEndTime) external onlyOwner whenPaused {
        require(block.timestamp < endTime, "Sale ended");
        require(endTime < newEndTime, "Invalid new time");
        endTime = newEndTime;
    }

    function updateReceiver(address receiver) external onlyOwner whenPaused {
        require(receiver != address(0), "Invalid address");
        _receiver = receiver;
    }

}
