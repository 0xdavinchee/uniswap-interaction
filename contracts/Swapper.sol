//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Improvements (v2)
// - passing in the optimal path to execute the trade
// - using the uniswaplibrary maximize profit function
// - passing in other things into data for profitability
// - set up an express.js server to monitor prices
// - develop some sort of algorithm which checks prices
//   and takes profitable trades

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

    /**
     * Sends token from path[0] to path[1] on one exchange
     * and back from path[1] to path[0] on another
     */
    function executeBasicArbitrage(
        uint256 amountIn,
        address[] calldata path,
        bool isUniToSushi
    ) external {
        require(
            msg.sender == owner,
            "You are not allowed to call this contract."
        );

        IUniswapV2Router02 routerA = isUniToSushi ? uniRouter : sushiRouter;
        IUniswapV2Router02 routerB = isUniToSushi ? sushiRouter : uniRouter;

        uint256 amountOut = routerA.getAmountsOut(amountIn, path)[1];
        IERC20 initialToken = IERC20(path[0]);
        initialToken.approve(address(routerA), amountIn);
        uint256[] memory amounts =
            routerA.swapExactTokensForTokens(
                amountIn,
                amountOut,
                path,
                address(this),
                block.timestamp
            );

        IERC20 returnToken = IERC20(path[1]);
        address[] memory newPath = new address[](path.length);
        for (uint256 i = 0; i < path.length; i++) {
            newPath[i] = path[path.length - (i + 1)];
        }
        uint256 amountOutB = routerB.getAmountsOut(amounts[1], newPath)[1];
        returnToken.approve(address(routerB), amounts[1]);
        routerB.swapExactTokensForTokens(
            amounts[1],
            amountOutB,
            newPath,
            msg.sender,
            block.timestamp
        );
    }

    function executeFlashArbitrage(
        address _borrowToken,
        address _otherToken,
        uint256 _borrowAmount,
        bool _uniToSushi
    ) external {
        require(
            msg.sender == owner,
            "You are not allowed to call this contract."
        );

        address pairAddress =
            IUniswapV2Factory(_uniToSushi ? uniFactory : sushiFactory).getPair(
                _borrowToken,
                _otherToken
            );
        require(pairAddress != address(0), "Pair doesn't exist.");

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 amount0Out = _borrowToken == token0 ? _borrowAmount : 0;
        uint256 amount1Out = _borrowToken == token1 ? _borrowAmount : 0;

        pair.swap(
            amount0Out,
            amount1Out,
            address(this),
            abi.encode(_uniToSushi)
        );
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata data
    ) external {
        bool uniToSushi = abi.decode(data, (bool));
        address[] memory path = new address[](2); // going from new asset to borrowed asset
        address[] memory swapPath = new address[](2); // going from borrowed asset to new asset
        IUniswapV2Router02 returnRouter = uniToSushi ? uniRouter : sushiRouter;
        IUniswapV2Router02 tradeRouter = uniToSushi ? sushiRouter : uniRouter;
        uint256 lastIndex = path.length - 1;

        {
            address token0 = IUniswapV2Pair(msg.sender).token0();
            address token1 = IUniswapV2Pair(msg.sender).token1();
            require(
                msg.sender ==
                    IUniswapV2Factory(uniToSushi ? uniFactory : sushiFactory)
                        .getPair(token0, token1),
                "Ensure sender is a pair."
            );
            require(
                _sender == address(this),
                "You are unauthorized to call this."
            );
            require(
                _amount0 == 0 || _amount1 == 0,
                "Unidirectional trades only."
            );

            // specify the path is from not borrowed to borrowed (e.g. DAI TO WETH)
            path[0] = _amount0 == 0 ? token0 : token1;
            path[lastIndex] = _amount0 == 0 ? token1 : token0;

            // specify the trade path borrowed to not borrowed (e.g. WETH to DAI)
            for (uint256 i = 0; i < path.length; i++) {
                swapPath[i] = path[path.length - (i + 1)];
            }
        }

        // borrowAmount will be the non-zero amount
        uint256 borrowAmount = _amount0 == 0 ? _amount1 : _amount0;

        // we want to see how much DAI we need to return given the borrowed amount of path[1] (WETH)
        uint256 amountRequired =
            returnRouter.getAmountsIn(borrowAmount, path)[0];

        // we want to see how much DAI we will get (WETH => DAI) given borrowed amount of path[0] (WETH)
        uint256 amountOutputExpected =
            tradeRouter.getAmountsOut(borrowAmount, swapPath)[lastIndex];
        require(
            amountOutputExpected > amountRequired,
            "This is not profitable."
        );

        IERC20(swapPath[0]).approve(address(tradeRouter), borrowAmount);

        tradeRouter.swapExactTokensForTokens(
            borrowAmount,
            amountOutputExpected,
            swapPath,
            address(this),
            block.timestamp
        );

        // transfer amount required to uniswap pair
        IERC20(swapPath[lastIndex]).transfer(msg.sender, amountRequired);

        // calculate the remaining amount left (profit) and return to EOA owner.
        uint256 profit = amountOutputExpected - amountRequired;
        IERC20(swapPath[lastIndex]).transfer(owner, profit);
    }

    function withdrawEth() external payable {
        require(msg.sender == owner);
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Could not withdraw.");
    }

    receive() external payable {}
}
