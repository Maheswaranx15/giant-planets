// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract AccessControl is Pausable {

    address public owner;
    address internal _proposedOwner;
    uint256 private _deadline;
    mapping(address => bool) public operators;
    
    event Unlocked(address account);
    event SetOperator(address indexed admin, bool state);
    event NewOwner(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Unauthorized");
        _;
    }

    receive() external virtual payable {revert("Revert payable unassigned");}

    fallback() external {revert("Unassigned");}

    function setOperator(address operator, bool state) external onlyOwner () {
        if (operators[operator] != state) {
            operators[operator] = state;
            emit SetOperator(operator, state);
        }
    }

    function transferOwnership(address newOwner, uint256 duration) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        _deadline = block.timestamp + duration;
        _proposedOwner = newOwner;
    }

    function cancelTransferOwnership() external onlyOwner {
        _deadline = 0;
        _proposedOwner = address(0);
    }

    function takeOwnership() external {
        require(msg.sender == _proposedOwner, "Not proposed");
        require(_deadline > block.timestamp, "Deadline passed");
        if (operators[owner]) {
            operators[owner] = false;
        }
        owner = msg.sender;
        _proposedOwner = address(0);
        emit NewOwner(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}
