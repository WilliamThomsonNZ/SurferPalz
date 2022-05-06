// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameToken is ERC20Capped, Ownable {
    constructor(uint256 _cap) ERC20("GameToken", "GT") ERC20Capped(_cap) {}

    mapping(address => bool) controllers;

    function mint(address _to, uint256 _amount) external {
        require(totalSupply() + _amount <= cap(), "MAX_SUPPLY_REACHED");
        require(
            controllers[msg.sender] = true,
            "Only controllers can mint tokens"
        );
        _mint(_to, _amount);
    }

    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }
}
