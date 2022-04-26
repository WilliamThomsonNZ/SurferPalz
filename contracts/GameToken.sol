// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameToken is ERC20, Ownable {
    constructor() ERC20("GameToken", "GT") {}

    mapping(address => bool) controllers;

    function mint(address _to, uint256 _amount) external {
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
