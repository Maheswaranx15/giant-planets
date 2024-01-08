// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./access/AccessControl.sol";

interface WrappedEther {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract TokenSaleV2 is AccessControl {


    event PurchasedTokens (
        address indexed buyer,
        uint256 amount
    );

    IERC20 public payToken;
    ISwapRouter public immutable swapRouter;
    WrappedEther public immutable IWETH;
    uint24 public constant poolFee = 500;

    uint256 public totalItems;
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

    constructor(
        address receiver, 
        ISwapRouter swapRouter_, 
        IERC20 payToken_, 
        WrappedEther wrappedEther_,
        uint256 itemValue_, 
        uint256 startTime_, 
        uint256 endTime_) 
    {
        owner = msg.sender;

        swapRouter = swapRouter_;
        payToken = payToken_;
        IWETH = wrappedEther_;
        
        itemValue = itemValue_;
        startTime = startTime_;
        endTime = endTime_;
        _receiver = receiver;
    }

    receive() external virtual override payable {
        require(msg.sender == address(IWETH), "Revert payable unassigned");
    }

    function purchaseWithEther(uint8 amount, uint256 payAmount) payable external duringSale whenNotPaused {
        require(amount > 0 && payAmount > 0, "Amount 0");
        require(amount + purchasedItems[msg.sender] <= 100, "Limit reached");
        require(payAmount == msg.value, "Wrong ETH amount");
        
        uint256 stableAmount = amount * itemValue;
        uint256 prevBalance = payToken.balanceOf(_receiver);

        IWETH.deposit{value: msg.value}();
        TransferHelper.safeApprove(address(IWETH), address(swapRouter), payAmount);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(IWETH),
                tokenOut: address(payToken),
                fee: poolFee,
                recipient: _receiver,
                deadline: block.timestamp,
                amountOut: stableAmount,
                amountInMaximum: payAmount,
                sqrtPriceLimitX96: 0
            }
        );

        uint256 amountIn = swapRouter.exactOutputSingle(params);
        require(payToken.balanceOf(_receiver) == prevBalance + stableAmount, "Swap failed");

        purchasedItems[msg.sender] += amount;
        totalItems += amount;

        if (amountIn < payAmount) {
            TransferHelper.safeApprove(address(IWETH), address(swapRouter), 0);
            IWETH.withdraw(payAmount - amountIn);
            (bool success, ) = msg.sender.call{value: msg.value - amountIn}("");
            require(success, "Failed to refund ether");
        }

        emit PurchasedTokens(msg.sender, amount);
    }

    function purchase(uint8 amount, uint256 payAmount) external duringSale whenNotPaused {
        require(amount > 0 && payAmount > 0, "Amount 0");
        require(amount + purchasedItems[msg.sender] <= 100, "Limit reached");
        require(amount * itemValue == payAmount, "Wrong amounts");
        purchasedItems[msg.sender] += amount;
        totalItems += amount;
        bool success = payToken.transferFrom(msg.sender, _receiver, payAmount);
        require(success, "Transfer failed");
        emit PurchasedTokens(msg.sender, amount);
    }

    function withdrawEther() external onlyOwner afterSale {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Ether transfer failed");  
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
