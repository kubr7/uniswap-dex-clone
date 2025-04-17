//contracts/UniswapDEX.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract UniswapDEX {
    IERC20 public tokenA;
    IERC20 public tokenB;
    LPToken public lpToken;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;

    event Swap(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityBurned);

    constructor(address _tokenA, address _tokenB, address _lpToken) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = LPToken(_lpToken);
    }

    // Add liquidity function
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidityMinted;
        if (totalLiquidity == 0) {
            liquidityMinted = sqrt(amountA * amountB);
        } else {
            liquidityMinted = min(
                (amountA * totalLiquidity) / reserveA,
                (amountB * totalLiquidity) / reserveB
            );
        }

        require(liquidityMinted > 0, "Zero liquidity minted");

        reserveA += amountA;
        reserveB += amountB;
        totalLiquidity += liquidityMinted;

        lpToken.mint(msg.sender, liquidityMinted);

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidityMinted);
    }

    // Remove liquidity function
    function removeLiquidity(uint256 liquidity) external {
        require(lpToken.balanceOf(msg.sender) >= liquidity, "Not enough liquidity");

        uint256 amountA = (liquidity * reserveA) / totalLiquidity;
        uint256 amountB = (liquidity * reserveB) / totalLiquidity;

        lpToken.burn(msg.sender, liquidity);

        reserveA -= amountA;
        reserveB -= amountB;
        totalLiquidity -= liquidity;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    // Swap Token A to Token B
    function swapAforB(uint256 amountIn) external {
        require(amountIn > 0, "Invalid amount");

        tokenA.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = getAmountOut(amountIn, reserveA, reserveB);
        tokenB.transfer(msg.sender, amountOut);

        reserveA += amountIn;
        reserveB -= amountOut;

        emit Swap(msg.sender, address(tokenA), amountIn, address(tokenB), amountOut);
    }

    // Swap Token B to Token A
    function swapBforA(uint256 amountIn) external {
        require(amountIn > 0, "Invalid amount");

        tokenB.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = getAmountOut(amountIn, reserveB, reserveA);
        tokenA.transfer(msg.sender, amountOut);

        reserveB += amountIn;
        reserveA -= amountOut;

        emit Swap(msg.sender, address(tokenB), amountIn, address(tokenA), amountOut);
    }

    // Get swap output using constant product formula with 0.3% fee
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }

    // Helpers
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 y) public pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
