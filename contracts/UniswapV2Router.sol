// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
    function createPair(address tokenA, address tokenB) external returns (address);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IWFYRO {
    function deposit() external payable;
    function withdraw(uint) external;
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external returns (bool);
}

contract UniswapV2Router {
    address public factory;
    address public WFYRO;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WFYRO) {
        factory = _factory;
        WFYRO = _WFYRO;
    }

    receive() external payable {
        assert(msg.sender == WFYRO);
    }

    // ── Liquidity ──────────────────────────────────────────────────

    function addLiquidity(
        address tokenA, address tokenB,
        uint amountADesired, uint amountBDesired,
        uint amountAMin, uint amountBMin,
        address to, uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        amountA = amountADesired;
        amountB = amountBDesired;
        require(amountA >= amountAMin && amountB >= amountBMin, 'Router: INSUFFICIENT_AMOUNT');
        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
    }

    function addLiquidityFYRO(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFYROMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountFYRO, address pair) {
        pair = IUniswapV2Factory(factory).getPair(token, WFYRO);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(factory).createPair(token, WFYRO);
        }
        amountToken = amountTokenDesired;
        amountFYRO = msg.value;
        require(amountToken >= amountTokenMin && amountFYRO >= amountFYROMin, 'Router: INSUFFICIENT_AMOUNT');
        IWFYRO(WFYRO).deposit{value: amountFYRO}();
        IWFYRO(WFYRO).transfer(pair, amountFYRO);
        IERC20(token).transferFrom(msg.sender, pair, amountToken);
    }

    // ── Swap ───────────────────────────────────────────────────────

    function swapExactTokensForTokens(
        uint amountIn, uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        for (uint i = 0; i < path.length - 1; i++) {
            amounts[i+1] = _getAmountOut(amounts[i], path[i], path[i+1]);
            require(amounts[i+1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT');
            IERC20(path[i+1]).transfer(to, amounts[i+1]);
        }
    }

    function swapExactFYROForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WFYRO, 'Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = msg.value;
        IWFYRO(WFYRO).deposit{value: msg.value}();
        for (uint i = 0; i < path.length - 1; i++) {
            amounts[i+1] = _getAmountOut(amounts[i], path[i], path[i+1]);
            require(amounts[i+1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT');
        }
        IERC20(path[path.length-1]).transfer(to, amounts[amounts.length-1]);
    }

    // ── Price calculation ──────────────────────────────────────────

    function _getAmountOut(uint amountIn, address tokenIn, address tokenOut)
        internal view returns (uint amountOut) {
        address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        require(pair != address(0), 'Router: PAIR_NOT_EXISTS');
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(pair).getReserves();
        address t0 = IUniswapV2Pair(pair).token0();
        (uint reserveIn, uint reserveOut) = tokenIn == t0 ? (uint(r0), uint(r1)) : (uint(r1), uint(r0));
        require(reserveIn > 0 && reserveOut > 0, 'Router: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut)
        external view returns (uint) {
        return _getAmountOut(amountIn, tokenIn, tokenOut);
    }
}
