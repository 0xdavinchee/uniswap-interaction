//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// unisw factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
// sushi factory: 0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
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
        uint256 _amount0Out,
        uint256 _amount1Out,
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

        // borrow 1 ETH for example
        // note: ensure that amount0 is actually tokenA and amount1 is actually _otherToken
        IUniswapV2Pair(pairAddress).swap(
            _amount0Out,
            _amount1Out,
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
        address[] memory path = new address[](2); // going from new asset to borrowed asset
        address[] memory swapPath = new address[](2); // going from borrowed asset to new asset
        bool uniToSushi = abi.decode(data, (bool));
        IUniswapV2Router02 returnRouter = uniToSushi ? uniRouter : sushiRouter;
        IUniswapV2Router02 tradeRouter = uniToSushi ? sushiRouter : uniRouter;

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

            // specify the path is from not borrowed to borrowed (e.g. UNI TO WETH)
            path[0] = _amount0 == 0 ? token0 : token1;
            path[1] = _amount0 == 0 ? token1 : token0;

            // specify the trade path borrowed to not borrowed (e.g. WETH to DAI)
            swapPath[0] = path[1];
            swapPath[1] = path[0];
        }

        // borrowAmount will be the non-zero amount
        uint256 borrowAmount = _amount0 == 0 ? _amount1 : _amount0;

        // we want to see how much UNI we need to return given the borrowed amount of path[1] (WETH)
        uint256 amountRequired =
            returnRouter.getAmountsIn(borrowAmount, path)[0];

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
        IERC20(swapPath[1]).approve(owner, profit);
        IERC20(swapPath[1]).transfer(owner, profit);
    }

    function withdrawTokens(address _tokenAddress) external {
        require(msg.sender == owner);
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0);
        token.approve(msg.sender, tokenBalance);
        token.transfer(msg.sender, tokenBalance);
    }

    function withdrawEth() external payable {
        require(msg.sender == owner);
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Could not withdraw.");
    }

    receive() external payable {}
}
