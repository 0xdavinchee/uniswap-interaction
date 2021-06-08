//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract QuickERC20 is ERC20 {
    address public owner;

    constructor() public ERC20("Quick", "QCK") {
        owner = msg.sender;
        _mint(msg.sender, 1000 * 10**18);
    }

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}
