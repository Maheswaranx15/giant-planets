// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GiantsPlanet} from "../GiantsPlanet.sol";
import "../access/AccessControl.sol";

contract Airdrops is AccessControl {

    GiantsPlanet public giantsPlanet;
    uint256 public id;

    constructor(address payable tokenAddress_, uint256 id_) {
        owner = msg.sender;
        giantsPlanet = GiantsPlanet(tokenAddress_);
        id = id_;
    }

    function airdrop(address to, uint256 amount, bytes calldata data) external onlyOwner {
        giantsPlanet.mint(to, id, amount, data);
    }

    function batchAidrop(address[] memory accounts, uint256[] memory amounts, bytes calldata data) external onlyOwner {
        require(accounts.length == amounts.length, "Array mismatch");
        for (uint i = 0; i < accounts.length; i++) {
            giantsPlanet.mint(accounts[i], id, amounts[i], data);
        }   
    }

    function refund(address tokenAddress, address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Array mismatch");
        for (uint i = 0; i < accounts.length; i++) {
            require(IERC20(tokenAddress).transferFrom(msg.sender, accounts[i], amounts[i]), "Transfer failed");
        }   
    }

}