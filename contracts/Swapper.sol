//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "hardhat/console.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swapper {
    IUniswapV2Router02 public router;
    address public owner;

    event Amount(uint256 amount);

    constructor(address _router) public {
        router = IUniswapV2Router02(_router);
        owner = msg.sender;
    }

    function getTokenBalance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdrawToken(IERC20 token) external {
        require(msg.sender == owner);
        token.approve(msg.sender, token.balanceOf(address(this)));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function checkAmountsOut(uint256 amountIn, address[] calldata path)
        external
        returns (uint256)
    {
        uint256 amount = router.getAmountsOut(amountIn, path)[1];
        emit Amount(amount);
        return amount;
    }

    function checkAmountsIn(uint256 amountOut, address[] calldata path)
        external
        returns (uint256)
    {
        uint256 amount = router.getAmountsIn(amountOut, path)[0];
        emit Amount(amount);
        return amount;
    }

    /** Swaps an exact amount of input tokens for as many output tokens based on
     * the getAmountsOut function.
     */
    function swapExactTokensForTokens(uint256 amountIn, address[] calldata path)
        external
        returns (uint256[] memory)
    {
        // get the token interface for the input token and
        // allow the router to spend it
        IERC20 token = IERC20(path[0]);
        token.approve(address(router), amountIn);
        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256[] memory amounts =
            router.swapExactTokensForTokens(
                amountIn,
                amountsOut[1],
                path,
                msg.sender,
                block.timestamp
            );
        return amounts;
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    ) external returns (uint256[] memory) {
        IERC20 token = IERC20(path[0]);
        token.approve(address(router), amountInMax);
        uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
        uint256[] memory amounts =
            router.swapTokensForExactTokens(
                amountOut,
                amountsIn[0],
                path,
                msg.sender,
                block.timestamp
            );
        return amounts;
    }

    function swapExactETHforTokens(address[] calldata path)
        external
        payable
        returns (uint256[] memory)
    {
        uint256[] memory amountsOut = router.getAmountsOut(msg.value, path);
        uint256[] memory amounts =
            router.swapExactETHForTokens(
                amountsOut[1],
                path,
                msg.sender,
                block.timestamp
            );
        return amounts;
    }

    function swapTokensForExactETH(uint256 amountOut, address[] calldata path)
        external
        returns (uint256[] memory)
    {
        uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
        uint256[] memory amounts =
            router.swapTokensForExactETH(
                amountOut,
                amountsIn[0],
                path,
                msg.sender,
                block.timestamp
            );
        return amounts;
    }

    function swapExactTokensForETH(uint256 amountIn, address[] calldata path)
        external
        returns (uint256[] memory)
    {
        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256[] memory amounts =
            router.swapExactTokensForETH(
                amountIn,
                amountsOut[1],
                path,
                msg.sender,
                block.timestamp
            );
        return amounts;
    }

    function swapETHForExactTokens(address[] calldata path)
        external
        payable
        returns (uint256[] memory)
    {
        uint256[] memory amountsOut = router.getAmountsOut(msg.value, path);
        uint256[] memory amounts =
            router.swapETHForExactTokens(
                amountsOut[1],
                path,
                msg.sender,
                block.timestamp
            );
        return amounts;
    }
}
