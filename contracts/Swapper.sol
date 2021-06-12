//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "hardhat/console.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// rinkeby DAI: 0xc7ad46e0b8a400bb3c915120d284aafba8fc4735
// rinkeby UNI: 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
// rinkeby WETH: 0xc778417e063141139fce010982780140aa0cd5ab
// uni: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
// sushi: 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506

contract Swapper {
    IUniswapV2Factory public uniFactory;
    IUniswapV2Factory public sushiFactory;
    IUniswapV2Router02 public uniRouter;
    IUniswapV2Router02 public sushiRouter;
    address public owner;

    constructor(
        IUniswapV2Factory _uniFactory,
        IUniswapV2Factory _sushiFactory,
        IUniswapV2Router02 _uniRouter,
        IUniswapV2Router02 _sushiRouter
    ) public {
        uniFactory = _uniFactory;
        sushiFactory = _sushiFactory;
        uniRouter = _uniRouter;
        sushiRouter = _sushiRouter;
        owner = msg.sender;
    }

    function executeArbitrage(
        address tokenA,
        address tokenB,
        uint256 amount0Out,
        uint256 amount1Out,
        bool uniToSushi
    ) external {
        require(
            msg.sender == owner,
            "You are not allowed to call this contract."
        );

        address pair =
            IUniswapV2Factory(uniToSushi ? uniFactory : sushiFactory).getPair(
                tokenA,
                tokenB
            );
        require(pair != address(0), "Pair doesn't exist.");

        // borrow 1 ETH for example
        // note: ensure that amount0 is actually tokenA and amount1 is actually tokenB
        IUniswapV2Pair(pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            abi.encode(uniToSushi)
        );
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        address[] memory path = new address[](2); // going from new asset to borrowed asset
        address[] memory swapPath = new address[](2); // going from borrowed asset to new asset
        bool uniToSushi = abi.decode(data, (bool));
        IUniswapV2Factory factory = uniToSushi ? uniFactory : sushiFactory;
        IUniswapV2Router02 tradeRouter = uniToSushi ? sushiRouter : uniRouter;

        {
            address token0 = IUniswapV2Pair(msg.sender).token0();
            address token1 = IUniswapV2Pair(msg.sender).token1();
            require(
                msg.sender ==
                    IUniswapV2Factory(factory).getPair(token0, token1),
                "Ensure sender is a pair."
            );
            require(
                amount0 == 0 || amount1 == 0,
                "Unidirectional trades only."
            );

            // specify the path is from not borrowed to borrowed (e.g. UNI TO WETH)
            path[0] = amount0 == 0 ? token0 : token1;
            path[1] = amount0 == 0 ? token1 : token0;

            // specify the trade path borrowed to not borrowed (e.g. WETH to DAI)
            swapPath[0] = path[1];
            swapPath[1] = path[0];
        }

        // borrowAmount will be the non-zero amount
        uint256 borrowAmount = amount0 == 0 ? amount1 : amount0;

        // we want to see how much UNI we need to return given the borrowed amount of path[1] (WETH)
        uint256 amountRequired =
            UniswapV2Library.getAmountsIn(address(factory), borrowAmount, path)[
                0
            ];

        // we want to see how much UNI we will get (WETH => UNI) given borrowed amount of path[0] (WETH)
        uint256 amountOutputExpected =
            tradeRouter.getAmountsOut(borrowAmount, swapPath)[1];
        require(
            amountOutputExpected > amountRequired,
            "This is not profitable."
        );

        IERC20(swapPath[0]).approve(address(tradeRouter), borrowAmount);

        // WETH to DAI trade
        tradeRouter.swapExactTokensForTokens(
            borrowAmount,
            amountOutputExpected,
            swapPath,
            address(this),
            block.timestamp
        );

        // approve amount required to uniswap pair
        IERC20(swapPath[1]).approve(msg.sender, amountRequired);

        // transfer amount required to uniswap pair
        IERC20(swapPath[1]).transfer(msg.sender, amountRequired);

        // calculate the remaining amount left (profit) and return to sender.
        uint256 profit = amountOutputExpected - amountRequired;
        IERC20(swapPath[1]).approve(sender, profit);
        IERC20(swapPath[1]).transfer(sender, profit);
    }
}
