// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./access/AccessControl.sol";
import "./utils/Counters.sol";

contract GiantsPlanet is AccessControl, ERC1155Supply {
    using Counters for Counters.Counter;

    event NewSeries(
        address indexed creator,
        uint256 id,
        string name
    );

    string public name;
    string public symbol;
    Counters.Counter public totalSeries;
    mapping(uint256 => string) public seriesNames;
    mapping(uint256 => uint256) public maxSupply;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC1155(_uri) {
        owner = msg.sender;
        operators[msg.sender] = true;
        name = _name;
        symbol = _symbol;
    }

    function uri(uint256 id) public view virtual override returns(string memory) {
        return string(abi.encodePacked(super.uri(id), Strings.toString(id)));    
    }

    function uri() public view virtual returns(string memory) {
        return super.uri(0);
    }

    function contractURI() public view virtual returns(string memory) {
        return super.uri(0);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOperator whenNotPaused {
        require(bytes(seriesNames[id]).length > 0, "Nonexistent series");
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOperator whenNotPaused {
        for (uint i = 0; i < ids.length; i++) {
            require(bytes(seriesNames[ids[i]]).length > 0, "Nonexistent series");
        }   
        _mintBatch(to, ids, amounts, data);
    }

    function newSeries(string memory _name, uint256 _maxSupply) external onlyOwner returns(uint256) {
        totalSeries.increment();
        uint256 id = totalSeries.current();
        seriesNames[id] = _name;
        maxSupply[id] = _maxSupply;
        emit NewSeries(msg.sender, id, name);
        return id;
    }

    function setName(uint256 id, string memory _name) external onlyOwner returns(string memory) {
        require(bytes(seriesNames[id]).length > 0, "Nonexistent series");
        require(keccak256(bytes(seriesNames[id])) != keccak256(bytes(_name)), "No change");
        seriesNames[id] = _name;
        return _name;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function withdrawEther() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        bool success = IERC20(tokenAddress).transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }
}
