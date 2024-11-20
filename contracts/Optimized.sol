// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface ISunswapV1Factory {
    function getExchange(address token) external view returns (address payable);
}

interface ISunswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISunswapV1Exchange {
    function tokenToTrxSwapInput(uint tokens_sold, uint min_trx, uint deadline) external returns (uint);
    function trxToTokenTransferInput(uint, uint, address) external payable returns(uint);
}

interface ISunswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Callee {
    function sunswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract Optimized is IUniswapV2Callee {
    ISunswapV1Factory private constant factoryV1 = ISunswapV1Factory(0xeEd9e56a5CdDaA15eF0C42984884a8AFCf1BdEbb);
    ISunswapV2Factory private constant factoryV2 = ISunswapV2Factory(0x689AbaeeEd3F0BB3585773192e23224CAC25Dd41);
    address private constant WRAPPED_TRX = 0x891cdb91d149f23B1a45D9c5Ca78a88d0cB44C18;
    address private owner;
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) private pure returns (uint amountIn) {
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) private pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    function getReservesV1(address token) private view returns(uint112 reserve0, uint112 reserve1, address pair) {
        pair = factoryV1.getExchange(token);
        
        if (pair == address(0)) {
            return (0, 0, address(0));
        }
        
        reserve0 = uint112(pair.balance);
        reserve1 = uint112(IERC20(token).balanceOf(pair));
    }
    
    function getReservesV2(address token0, address token1) private view returns (uint112 reserveIn, uint112 reserveOut, address pair) {
        pair = factoryV2.getPair(token0, token1);
        
        if (pair == address(0)) {
            return (0, 0, address(0));
        }

        (reserveIn, reserveOut, ) = ISunswapV2Pair(pair).getReserves();
        if (token0 > token1) {
            (reserveIn, reserveOut) = (reserveOut, reserveIn);
        }
    }
    
    function getReserves2(address token0, address token1) private view returns (uint112[5] memory X, uint112[5] memory Y) {
        (X[0], Y[0], ) = getReservesV1(token0);
        (X[1], Y[1], ) = getReservesV2(WRAPPED_TRX, token0);
        (X[2], Y[2], ) = getReservesV2(token0, token1);
        (Y[3], X[3], ) = getReservesV1(token1);
        (X[4], Y[4], ) = getReservesV2(token1, WRAPPED_TRX);
    }
    
    function swapV2(address token0, address token1, uint amountIn, uint amountOut, address to, bytes memory data) private returns (uint) {
        address pair = factoryV2.getPair(token0, token1);

        bool direction = token0 < token1;
        
        if (amountOut == 0) {
            uint reserveIn;
            uint reserveOut;
            (reserveIn, reserveOut, ) = ISunswapV2Pair(pair).getReserves();
            if (direction == false) {
                (reserveIn, reserveOut) = (reserveOut, reserveIn);
            }
            
            amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        }
        
        if (amountIn > 0) {
            IERC20(token0).transfer(pair, amountIn);
        }
        
        {
            uint amount0;
            uint amount1;
            (amount0, amount1) = direction ? (uint(0), amountOut) : (amountOut, uint(0));
            ISunswapV2Pair(pair).swap(amount0, amount1, to, data);
        }
        
        return amountOut;
    }
    
    function calc(uint C1, uint C2, uint C3) private pure returns (uint x, uint k) {
        uint temp = (C1 - C3);
        x = temp * C3 / C2;
        k = temp * temp / C2;
    }
    
    function calc1(uint X1, uint Y1, uint X2, uint Y2) private pure returns (uint x, uint k) {
        uint C1 = sqrt(Y1 * Y2 * 994009);
        uint C3 = sqrt(X1 * X2 * 1000000);
        
        if (C1 < C3) {
            return (0, 0);
        }
        
        uint C2 = X2 * 997000 + Y1 * 994009;
        
        (x, k) = calc(C1, C2, C3);
    }
    
    function calc2(uint X1, uint Y1, uint X2, uint Y2, uint X3, uint Y3) private pure returns (uint x, uint k) {
        uint C1 = sqrt(Y1 * Y2) * sqrt(Y3 * 991026973);
        uint C3 = sqrt(X1 * X2) * sqrt(X3 * 1000000000);
        
        if (C1 < C3) {
            return (0, 0);
        }
        
        uint C2 = 997000000 * X2 * X3 + (X3 * 994009000 + Y2 * 991026973) * Y1;
        
        (x, k) = calc(C1, C2, C3);
    }
    
    function expect1(address token, uint reserve) external view returns (uint k, uint r) {
        
        if (msg.sender != owner) {
            return (0, 0);
        }
        // require(msg.sender == owner, "Not owner");
        
        uint112 amount0 = uint112(reserve);
        uint112 amount1 = uint112(reserve >> 112);
        uint flag = reserve >> 224;
        
        if (flag >=4) {
            return (0, 0);
        }
        // require(flag < 4, "Invalid Input");
        
        uint X1;
        uint Y1;
        uint X2;
        uint Y2;
        
        (X1, Y1, ) = getReservesV1(token);
        
        r = Y2;
        
        if (flag & 1 == 0) {
            (X2, Y2, ) = getReservesV2(token, WRAPPED_TRX);
        } else {
            (X2, Y2, ) = getReservesV2(WRAPPED_TRX, token);
        }
        
        if (X1 == 0 || X2 == 0 || Y1 == 0 || Y2 == 0) {
            return (0, 0);
        }

        // require(X1 > 0 && X2 > 0 && Y1 > 0 && Y2 > 0, "Invalid Pair");
        
        if (amount0 > 0 || amount1 > 0) {
            if (flag & 2 == 0) {
                uint112 amountOut = uint112(getAmountOut(amount0, Y2, X2));
                if (amountOut <= amount1) {
                    return (0, 0);
                }
                // require(amountOut > amount1, "Low possibility");
                X2 -= amountOut;
                Y2 += amount0;
            } else {
                uint112 amountIn = uint112(getAmountIn(amount0, Y2, X2));
                if (amount1 <= amountIn) {
                    return (0, 0);
                }
                // require(amountIn < amount1, "Low possibility");
                Y2 += amountIn;
                X2 -= amount0;
            }
        }

        if (flag & 1 == 0) {
            (X1, Y1, X2, Y2) = (X1, Y1, X2, Y2);
            // (X1, Y1, ) = getReservesV1(token);
            // (X2, Y2, ) = getReservesV2(token, WRAPPED_TRX);
        } else {
            (X1, Y1, X2, Y2) = (X2, Y2, Y1, X1);
            // (X1, Y1, ) = getReservesV2(WRAPPED_TRX, token);
            // (Y2, X2, ) = getReservesV1(token);
        }
        
        uint x;
        
        (x, k) = calc1(X1, Y1, X2, Y2);
        
        uint y2 = x + k;
        uint y1 = getAmountIn(y2, X2, Y2);
        uint y0 = getAmountIn(y1, X1, Y1);
        
        if (y0 >= y2) {
            return (0, 0);
        }
        
        uint y = flag & 1 == 0 ? y2 : y1;
        k = y2 - y0;
        r = (flag & 1) << 224 | y << 112 | r;
    }
    
    function expect2(address token0, address token1, uint reserve) external view returns (uint k, uint r) {
        
        require(msg.sender == owner, "Not owner");
        
        uint112 amount0 = uint112(reserve);
        uint112 amount1 = uint112(reserve >> 112);
        uint flag = reserve >> 224;
        
        require(flag < 4, "Invalid Input");
        
        (uint112[5] memory X, uint112[5] memory Y) = getReserves2(token0, token1);
        
        require(X[2] > 0 && Y[2] > 0, "Invalid Pair");
        
        r = Y[2];
        
        if (amount0 > 0 || amount1 > 0) {
            if (flag == 0) {
                uint112 amountOut = uint112(getAmountOut(amount0, Y[2], X[2]));
                require(amountOut > amount1, "Low possibility");
                X[2] -= amountOut;
                Y[2] += amount0;
            } else { // 2
                uint112 amountIn = uint112(getAmountIn(amount0, Y[2], X[2]));
                require(amountIn < amount1, "Low possibility");
                Y[2] += amountIn;
                X[2] -= amount0;
            }
        }

        uint x;
        uint route;
        
        for (uint8 i = 0; i < 2; i ++) {
            if (X[i] == 0) {
                continue;
            }
            
            for (uint8 j = 3; j < 5; j ++) {
                if (X[j] == 0) {
                    continue;
                }
                
                uint tempX;
                uint tempK;
                (tempX, tempK) = calc2(X[i], Y[i], X[2], Y[2], X[j], Y[j]);
                if (tempK > k) {
                    (x, k) = (tempX, tempK);
                    route = (i << 1) + (j - 3);
                }
            }
        }
        
        if (k > 0) {
            uint i = (route & 2) >> 1;
            uint j = (route & 1) + 3;

            uint y3 = x + k;
            uint y2 = getAmountIn(y3, X[j], Y[j]);
            uint y1 = getAmountIn(y2, X[2], Y[2]);
            uint y0 = getAmountIn(y1, X[i], Y[i]);
            
            k = y3 - y0;
            r = route << 224 | y2 << 112 | r;
        }
    }
    
    function run1(address token, uint r) external {
        
        require(msg.sender == owner, "Not owner");
        
        uint Y1;
        address token0;
        address token1;
        uint112 Y = uint112(r);
        uint112 y = uint112(r >> 112);
        uint8 route = uint8(r >> 224);
        
        require(route < 4, "Invalid Input");
        
        if (route & 1 == 0) {
            (token0, token1) = (token, WRAPPED_TRX);
        } else {
            (token0, token1) = (WRAPPED_TRX, token);
        }
        
        (, Y1, ) = getReservesV2(token0, token1);
        require(Y < Y1, "Yet");
        
        bytes memory data = new bytes(1);
        data[0] = bytes1(route);

        swapV2(token0, token1, 0, y, address(this), data);
    }
    
    function run2(address token0, address token1, uint r) external {
        
        require(msg.sender == owner, "Not owner");
        
        uint112 Y = uint112(r);
        uint112 y = uint112(r >> 112);
        uint8 route = uint8(r >> 224);
        
        require(route < 4, "Invalid Input");
        
        uint112 Y2;
        (, Y2, ) = getReservesV2(token0, token1);
        
        require(Y < Y2, "Yet");

        bytes memory data = new bytes(1);
        data[0] = bytes1(route | 4);
        swapV2(token0, token1, 0, y, address(this), data);
    }
    
    function sunswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) override external {
        require(data.length == 1, "Invalid Input");
        require(sender == address(this), "Invalid sender");
        
        uint flag = uint(uint8(data[0]));
        
        require(flag < 8, "Invalid Input");
        
        address token0;
        address token1;
        
        uint y1;
        uint y2;
            
        (token0, token1, y2) = amount0 == 0 ? 
            (ISunswapV2Pair(msg.sender).token0(), ISunswapV2Pair(msg.sender).token1(), amount1) : 
            (ISunswapV2Pair(msg.sender).token1(), ISunswapV2Pair(msg.sender).token0(), amount0);
            
        {
            uint reserveIn;
            uint reserveOut;
            (reserveIn, reserveOut, ) = ISunswapV2Pair(msg.sender).getReserves();
            if (amount0 != 0) {
                (reserveIn, reserveOut) = (reserveOut, reserveIn);
            }
            y1 = getAmountIn(y2, reserveIn, reserveOut);
        }
        
        if (flag & 4 == 0) {
            if (flag == 0) {
                uint X;
                uint Y;
                address pair;
                (X, Y, pair) = getReservesV1(token0);
                uint y0 = getAmountIn(y1, X, Y);
                require(y0 < y2, "No3");
                IWETH(WRAPPED_TRX).withdraw(y2);
                ISunswapV1Exchange(pair).trxToTokenTransferInput{value: y0}(1, block.timestamp, msg.sender);
            } else {
                address pair = factoryV1.getExchange(token1);
                IERC20(token1).approve(pair, y2);
                uint y3 = ISunswapV1Exchange(pair).tokenToTrxSwapInput(y2, 1, block.timestamp);
                require(y3 > y1, "No3");
                IWETH(WRAPPED_TRX).deposit{value: y1}();
                IERC20(WRAPPED_TRX).transfer(msg.sender, y1);
            }
        } else {
            
            uint x;
            uint y3;
            
            flag = flag & 3;
            
            if (flag & 1 == 0) {
                address pair = factoryV1.getExchange(token1);
                IERC20(token1).approve(pair, y2);
                y3 = ISunswapV1Exchange(pair).tokenToTrxSwapInput(y2, 1, block.timestamp);
            } else {
                y3 = swapV2(token1, WRAPPED_TRX, y2, 0, address(this), new bytes(0));
            }
            
            address pair0;
            
            {
                uint reserveIn;
                uint reserveOut;
                
                if (flag & 2 == 0) {
                    pair0 = factoryV1.getExchange(token0);
                    reserveIn = pair0.balance;
                    reserveOut = IERC20(token0).balanceOf(pair0);
                } else {
                    (reserveIn, reserveOut, pair0) = getReservesV2(WRAPPED_TRX, token0);
                }
                
                x = getAmountIn(y1, reserveIn, reserveOut);
            }
            
            if (flag == 1) {
                IWETH(WRAPPED_TRX).withdraw(y3);
            } else if (flag == 2) {
                IWETH(WRAPPED_TRX).deposit{value: x}();
            } else if (flag == 3) {
                IWETH(WRAPPED_TRX).withdraw(y3 - x);
            }
            
            if (flag & 2 == 0) {
                ISunswapV1Exchange(pair0).trxToTokenTransferInput{value: x}(1, block.timestamp, msg.sender);
            } else {
                IERC20(WRAPPED_TRX).transfer(pair0, x);
                (amount0, amount1) = WRAPPED_TRX < token0 ? (uint(0), y1) : (y1, uint(0));
                ISunswapV2Pair(pair0).swap(amount0, amount1, msg.sender, new bytes(0));
            }
        }
    }
    
    function withdraw(address payable _to) external {
        require(msg.sender == owner, "Not owner");
        _to.transfer(address(this).balance);
    }
    
    function destroy(address payable _to) external {
        require(msg.sender == owner, "Not owner");
        selfdestruct(_to);
    }
    
    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }
    
    receive() payable external {}
}
