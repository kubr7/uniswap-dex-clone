//contracts/UniswapDEX.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract UniswapDEX {
    // Updated variable names
    IERC20 public nebulaCoin;
    IERC20 public fluxToken;
    LPToken public lpToken;

    uint256 public reserveNebula;
    uint256 public reserveFlux;
    uint256 public totalLiquidity;

    event Swap(
        address indexed trader,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );
    event LiquidityAdded(
        address indexed provider,
        uint256 amountNebula,
        uint256 amountFlux,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountNebula,
        uint256 amountFlux,
        uint256 liquidityBurned
    );

    constructor(address _nebula, address _flux, address _lpToken) {
        nebulaCoin = IERC20(_nebula);
        fluxToken = IERC20(_flux);
        lpToken = LPToken(_lpToken);
    }

    // Add liquidity function
    function addLiquidity(uint256 amountNebula, uint256 amountFlux) external {
        require(amountNebula > 0 && amountFlux > 0, "Invalid amounts");

        nebulaCoin.transferFrom(msg.sender, address(this), amountNebula);
        fluxToken.transferFrom(msg.sender, address(this), amountFlux);

        uint256 liquidityMinted;
        if (totalLiquidity == 0) {
            liquidityMinted = sqrt(amountNebula * amountFlux);
        } else {
            liquidityMinted = min(
                (amountNebula * totalLiquidity) / reserveNebula,
                (amountFlux * totalLiquidity) / reserveFlux
            );
        }

        require(liquidityMinted > 0, "Zero liquidity minted");

        reserveNebula += amountNebula;
        reserveFlux += amountFlux;
        totalLiquidity += liquidityMinted;

        lpToken.mint(msg.sender, liquidityMinted);

        emit LiquidityAdded(
            msg.sender,
            amountNebula,
            amountFlux,
            liquidityMinted
        );
    }

    // Remove liquidity function
    function removeLiquidity(uint256 liquidity) external {
        require(
            lpToken.balanceOf(msg.sender) >= liquidity,
            "Not enough liquidity"
        );

        uint256 amountNebula = (liquidity * reserveNebula) / totalLiquidity;
        uint256 amountFlux = (liquidity * reserveFlux) / totalLiquidity;

        lpToken.burn(msg.sender, liquidity);

        reserveNebula -= amountNebula;
        reserveFlux -= amountFlux;
        totalLiquidity -= liquidity;

        nebulaCoin.transfer(msg.sender, amountNebula);
        fluxToken.transfer(msg.sender, amountFlux);

        emit LiquidityRemoved(msg.sender, amountNebula, amountFlux, liquidity);
    }

    // Swap NebulaCoin for FluxToken
    function swapNebulaForFlux(uint256 amountIn) external {
        require(amountIn > 0, "Invalid amount");

        nebulaCoin.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = getAmountOut(amountIn, reserveNebula, reserveFlux);
        fluxToken.transfer(msg.sender, amountOut);

        reserveNebula += amountIn;
        reserveFlux -= amountOut;

        emit Swap(
            msg.sender,
            address(nebulaCoin),
            amountIn,
            address(fluxToken),
            amountOut
        );
    }

    // Swap FluxToken for NebulaCoin
    function swapFluxForNebula(uint256 amountIn) external {
        require(amountIn > 0, "Invalid amount");

        fluxToken.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = getAmountOut(amountIn, reserveFlux, reserveNebula);
        nebulaCoin.transfer(msg.sender, amountOut);

        reserveFlux += amountIn;
        reserveNebula -= amountOut;

        emit Swap(
            msg.sender,
            address(fluxToken),
            amountIn,
            address(nebulaCoin),
            amountOut
        );
    }

    // Get swap output using constant product formula with 0.3% fee
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
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
