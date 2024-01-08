// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../access/AccessControl.sol";
import "./Counters.sol";

contract Payouts is AccessControl {
    using Counters for Counters.Counter;

    struct Payout{
        address fundingAccount;
        uint256 totalAmount;
        uint256 amount;
        mapping(address => bool) claimed;
    }

    event PayoutFunded(
        address indexed fundingAccount,
        uint256 amount,
        uint256 payoutId
    );

    event Claim(
        address indexed holder,
        uint256 tokenAmount,
        uint256 amountClaimed,
        uint256 payoutId
    );

    Counters.Counter public totalPayouts;
    address public payoutTokenAddress;

    address public tokenAddress;
    uint256 public tokenTotalSupply;
    uint256 public tokenId;
    uint256 private _currentBalance;
    mapping(uint256 => Payout) public payouts;

    constructor(address payoutTokenAddress_, address tokenAddress_, uint256 tokenTotalSupply_, uint256 tokenId_) {
        owner = msg.sender;
        payoutTokenAddress = payoutTokenAddress_;
        tokenAddress = tokenAddress_;
        tokenId = tokenId_;
        tokenTotalSupply = tokenTotalSupply_;
    }

    function claimSingle(uint256 payoutId) external {
        _claim(payoutId, msg.sender);
    }

    function claimSingleFor(uint256 payoutId, address toAddress) external {
        _claim(payoutId, toAddress);
    }

    function batchClaim(uint256[] memory payoutIds) external {
        for (uint i = 0; i < payoutIds.length; i++) {
            _claim(payoutIds[i], msg.sender);
        }    
    }

    function batchClaimFor(uint256[] memory payoutIds, address toAddress) external {
        for (uint i = 0; i < payoutIds.length; i++) {
            _claim(payoutIds[i], toAddress);
        }    
    }

    function deposit(uint256 amount) external onlyOperator whenNotPaused {
        require(amount > 0, "Zero");
        //require(amount % totalTokens == tokenTotalSupply, "Amount not divisible by token supply");

        bool success = IERC20(payoutTokenAddress).transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit failed");
        _currentBalance += amount;
        totalPayouts.increment();
        uint256 payoutId = totalPayouts.current();

        payouts[payoutId].fundingAccount = msg.sender;
        payouts[payoutId].totalAmount = amount;
        payouts[payoutId].amount = amount / tokenTotalSupply;

        emit PayoutFunded(msg.sender, amount, totalPayouts.current());
    }

    function emergencyWithdraw() external onlyOwner whenPaused {
        bool success = IERC20(payoutTokenAddress).transferFrom(address(this), msg.sender, _currentBalance);
        require(success, "Transfer failed");
    }

    function _claim(uint256 _payoutId, address _toAddress) private whenNotPaused {

        require(payouts[_payoutId].amount > 0, "Invalid payoutId");
        
        uint256 tokenBalance = IERC1155(tokenAddress).balanceOf(_toAddress, tokenId);
        require(tokenBalance > 0, "No tokens");
        require(!payouts[_payoutId].claimed[_toAddress], "Already claimed");

        payouts[_payoutId].claimed[_toAddress] = true;
        uint256 finalPayout = tokenBalance * payouts[_payoutId].amount;

        bool success = IERC20(payoutTokenAddress).transferFrom(address(this), _toAddress, finalPayout);
        require(success, "Transfer failed");

        emit Claim(_toAddress, tokenBalance, finalPayout, _payoutId);
    }
}
