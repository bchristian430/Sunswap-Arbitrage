// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV1Exchange.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Callee.sol";

import "./libraries/Math.sol";
import "./libraries/Utils.sol";
import "./libraries/UniswapUtil.sol";
import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Constants.sol";

contract Optimized is IUniswapV2Callee {
// contract Optimized {
    
    using SafeMath  for uint;
    using UQ112x112 for uint224;
    
    // Mainnet
    // IUniswapV1Factory internal constant factoryV1 = IUniswapV1Factory(0xeEd9e56a5CdDaA15eF0C42984884a8AFCf1BdEbb);
    // IUniswapV2Factory internal constant factoryV2 = IUniswapV2Factory(0x689AbaeeEd3F0BB3585773192e23224CAC25Dd41);
    // address internal constant WRAPPED_TRX = 0x891cdb91d149f23B1a45D9c5Ca78a88d0cB44C18;
    
    //Testnet
    // IUniswapV1Factory private constant factoryV1 = IUniswapV1Factory(0xE97E6ee12d3db8176242BB901fdB924cC938e2D9);
    // IUniswapV2Factory private constant factoryV2 = IUniswapV2Factory(0xc3bdaC99dFca480483f747D86Ee074BCFfe9Be55);
    // address private constant WRAPPED_TRX = 0xfb3b3134F13CcD2C81F4012E53024e8135d58FeE;
    address private owner;
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    function calc1(uint X1, uint Y1, uint X2, uint Y2) internal pure returns (uint k, uint x) {
        if (X1 == 0 || Y1 == 0 || X2 == 0 || Y2 == 0) {
            return (0, 0);
        }
        
        uint C1 = Y1 * Y2 * 994009;
        uint C3 = X1 * X2 * 1000000;
        
        if (C1 <= C3) {
            return (0, 0);
        }
        
        C1 = Math.sqrt(C1);
        C3 = Math.sqrt(C3);
        uint C2 = X2 * 997000 + Y1 * 994009;
        
        uint temp = C1 - C3;
        
        k = temp * temp / C2;
        x = temp * C3 / C2;
    }
    
    function expect1(address token, uint flag, uint amount, uint percent, uint inAmount, uint limit) external view returns(address pair0, address pair1, uint outAmount, uint k, uint x) {
        // flag & 1 => direction 0 - (trx->token->wtrx)wtrx->token detected 1(wtrx->token->trx) - token->wtrx detected
        // flag & 2 => 0 - in determined 1 - out determined
        // percent = 8
   
        uint[2] memory X;
        uint[2] memory Y;
        
        (X[0], Y[0], pair0) = UniswapUtil.getReservesV1(token);
        (X[1], Y[1], pair1) = UniswapUtil.getReservesV2(Constants.WRAPPED_TRX, token);
        
        if (flag & 1 == 0) {
            // detect wtrx -> token reserves are X[1], Y[1]
            
            if (amount > 0) {
                uint amountIn;
                uint amountOut;
                if (flag & 2 == 0) {
                    // inAmount determined
                    amountIn = amount;
                    amountOut = UniswapUtil.getAmountOut(amountIn, X[1], Y[1]);
                } else {
                    // outAmount determined
                    amountOut = amount;
                    amountIn = UniswapUtil.getAmountIn(amountOut, X[1], Y[1]);
                }
    
                if (amountIn * 1000 >= X[1] * percent) {
                    outAmount = UniswapUtil.getAmountOut(inAmount, X[1], Y[1]);
                }
    
                X[1] += amountIn;
                Y[1] -= amountOut;
            }
            
            // expect trx -> token -> wtrx
            (k, x) = calc1(X[0], Y[0], Y[1], X[1]);
        } else {
            // detect token -> wtrx
            
            if (amount > 0) {
                uint amountIn;
                uint amountOut;
                if (flag & 2 == 0) {
                    // inAmount determined
                    amountIn = amount;
                    amountOut = UniswapUtil.getAmountOut(amountIn, Y[1], X[1]);
                } else {
                    // outAmount determined
                    amountOut = amount;
                    amountIn = UniswapUtil.getAmountIn(amountOut, Y[1], X[1]);
                }
                X[1] -= amountOut;
                Y[1] += amountIn;
                (k, x) = calc1(X[1], Y[1], Y[0], X[0]);
            }
        }
        
        if (x > 0 && k >= limit) {
            x = uint(flag) << 224 | uint(limit) << 112 | x;
        } else {
            x = 0;
        }
    }
    
    function calc2(uint X1, uint Y1, uint X2, uint Y2, uint X3, uint Y3) internal pure returns (uint k, uint x) {
        if (X1 == 0 || Y1 == 0 || X2 == 0 || Y2 == 0 || X3 == 0 || Y3 == 0) {
            return (0, 0);
        }
        
        uint C1 = (Y1 * Y2 * 991026973).mul(Y3);
        uint C3 = (X1 * X2 * 1000000000).mul(X3);
        
        if (C1 <= C3) {
            return (0, 0);
        }
        
        C1 = Math.sqrt(C1);
        C3 = Math.sqrt(C3);
        uint C2 = X2 * X3 * 997000000 + Y1 * X3 * 994009000 + Y1 * Y2 * 991026973;
        
        uint temp = C1 - C3;
        
        k = temp * temp / C2;
        x = temp * C3 / C2;
    }
    
    function expect2(address token0, address token1, uint amount, uint limit, uint flag) external view returns(address pair0, address pair1, address pair2, uint k, uint x) {

        uint[5] memory X;
        uint[5] memory Y;
        address[4] memory pair;
        uint route;
        
        (X[2], Y[2], pair1) = UniswapUtil.getReservesV2(token0, token1);

        if (pair1 != address(0)) {
            
            if (amount > 0) {
                // detect token1 -> token0 reserves are Y[2], X[2]
                
                uint amountIn;
                uint amountOut;
                
                if (flag == 0) {
                    // inAmount determined
                    
                    amountIn = amount;
                    amountOut = UniswapUtil.getAmountOut(amountIn, Y[2], X[2]);
                } else {
                    // outAmount determined
                    
                    amountOut = amount;
                    amountIn = UniswapUtil.getAmountIn(amountOut, Y[2], X[2]);
                }
                
                X[2] -= amountOut;
                Y[2] += amountIn;
            }
            
    
            (X[0], Y[0], pair[0]) = UniswapUtil.getReservesV1(token0);
            (X[1], Y[1], pair[1]) = UniswapUtil.getReservesV2(Constants.WRAPPED_TRX, token0);
            (Y[3], X[3], pair[2]) = UniswapUtil.getReservesV1(token1);
            (X[4], Y[4], pair[3]) = UniswapUtil.getReservesV2(token1, Constants.WRAPPED_TRX);
            
            if (pair[0] != address(0)) {
                if (pair[2] != address(0)) {
                    uint tempk;
                    uint tempx;
                    
                    (tempk, tempx) = calc2(X[0], Y[0], X[2], Y[2], X[3], Y[3]);
                    
                    if (tempk > k) {
                        k = tempk;
                        x = tempx;
                        route = 0;
                        pair0 = pair[0];
                        pair2 = pair[2];
                    }
                }
                if (pair[3] != address(0)) {
                    uint tempk;
                    uint tempx;
                    
                    (tempk, tempx) = calc2(X[0], Y[0], X[2], Y[2], X[4], Y[4]);
                    
                    if (tempk > k) {
                        k = tempk;
                        x = tempx;
                        route = 2;
                        pair0 = pair[0];
                        pair2 = pair[3];
                    }
                }
            }
            
            if (pair[1] != address(0)) {
                if (pair[2] != address(0)) {
                    uint tempk;
                    uint tempx;
                    
                    (tempk, tempx) = calc2(X[1], Y[1], X[2], Y[2], X[3], Y[3]);
                    
                    if (tempk > k) {
                        k = tempk;
                        x = tempx;
                        route = 1;
                        pair0 = pair[1];
                        pair2 = pair[2];
                    }
                }
                if (pair[3] != address(0)) {
                    uint tempk;
                    uint tempx;
                    
                    (tempk, tempx) = calc2(X[1], Y[1], X[2], Y[2], X[4], Y[4]);
                    
                    if (tempk > k) {
                        k = tempk;
                        x = tempx;
                        route = 3;
                        pair0 = pair[1];
                        pair2 = pair[3];
                    }
                }
            }
            
            if (k >= limit && x > 0) {
                x = uint(route) << 224 | uint(limit) << 112 | x;
            } else {
                x = 0;
            }
        }
    }
    
    function front(address pair, address token, uint reserve) external payable {
        require(msg.value == 1);
        
        uint inAmount = uint112(reserve);
        uint outAmountMin = uint112(reserve >> 112);
        
        uint reserve0;
        uint reserve1;
        bool direction = Constants.WRAPPED_TRX < token;
        (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
        if (direction == false) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        
        uint outAmount = UniswapUtil.getAmountOut(inAmount, reserve0, reserve1);
        require(outAmount >= outAmountMin);
        
        uint out0;
        uint out1;
        
        (out0, out1) = direction ? (uint(0), outAmount) : (outAmount, uint(0));
        
        IERC20(Constants.WRAPPED_TRX).transfer(pair, inAmount);
        IUniswapV2Pair(pair).swap(out0, out1, address(this), new bytes(0));
    }
    
    function back(address pair, address token, uint outAmountMin) external {
        
        payable(msg.sender).transfer(1);

        bool direction = token < Constants.WRAPPED_TRX;

        uint reserve0;
        uint reserve1;

        (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
        if (direction == false) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        
        uint inAmount = IERC20(token).balanceOf(address(this));

        uint outAmount = UniswapUtil.getAmountOut(inAmount, reserve0, reserve1);

        require(outAmount >= outAmountMin);
        
        uint out0;
        uint out1;
        
        (out0, out1) = direction ? (uint(0), outAmount) : (outAmount, uint(0));
        
        IERC20(token).transfer(pair, inAmount);
        IUniswapV2Pair(pair).swap(out0, out1, address(this), new bytes(0));
    }
    
    function liquidate(address pair0, address pair1, address token) external {

        uint balance = address(this).balance;

        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
        
        uint reserve0;
        uint reserve1;
        uint reserve2;
        uint reserve3;
        
        uint outAmount1;
        
        uint inAmount = IERC20(token).balanceOf(address(this));
        
        require(inAmount > 0, "No balance");
        
        if (pair0 != address(0)) {
            reserve0 = IERC20(token).balanceOf(pair1);
            reserve1 = address(pair1).balance;
            outAmount1 = UniswapUtil.getAmountOut(inAmount, reserve0, reserve1);
        }
        
        uint outAmount2;
        bool direction;
        if (pair1 != address(0)) {
            
            direction = token < Constants.WRAPPED_TRX;
    
            (reserve2, reserve3, ) = IUniswapV2Pair(pair1).getReserves();
            if (direction == false) {
                (reserve2, reserve3) = (reserve3, reserve2);
            }
    
            outAmount2 = UniswapUtil.getAmountOut(inAmount, reserve2, reserve3);
        }
        
        require(outAmount1 > 0 || outAmount2 > 0, "Pairs not exist");
        
        if (outAmount1 > outAmount2) {
            IERC20(token).approve(pair0, inAmount);
            uint amountOut = IUniswapV1Exchange(pair0).tokenToTrxSwapInput(inAmount, outAmount1, block.timestamp);
            IWETH(Constants.WRAPPED_TRX).withdraw(amountOut);
        } else {
            uint out0;
            uint out1;
            
            (out0, out1) = direction ? (uint(0), outAmount2) : (outAmount2, uint(0));
            
            IERC20(token).transfer(pair1, inAmount);
            IUniswapV2Pair(pair1).swap(out0, out1, address(this), new bytes(0));
        }
    }
    
    function run1(address pair0, address pair1, address token, uint reserve) external {
        
        require(pair0 != address(0), "Invalid Pair");
        require(pair1 != address(0), "Invalid pair");
        
        uint112 x = uint112(reserve);
        uint112 limit = uint112(reserve >> 112);
        uint8 flag = uint8(reserve >> 224);

        uint reserve0 = pair0.balance;
        uint reserve1 = IERC20(token).balanceOf(pair0);
        uint reserve2;
        uint reserve3;
        
        (reserve2, reserve3, ) = IUniswapV2Pair(pair1).getReserves();
        
        if (token < Constants.WRAPPED_TRX) {
            (reserve2, reserve3) = (reserve3, reserve2);
        }
        
        uint112 y1;
        uint112 y2;
        
        if (flag & 1 == 0) {
            y1 = uint112(UniswapUtil.getAmountOut(x, reserve0, reserve1));
            y2 = uint112(UniswapUtil.getAmountOut(y1, reserve3, reserve2));
        } else {
            y1 = uint112(UniswapUtil.getAmountOut(x, reserve2, reserve3));
            y2 = uint112(UniswapUtil.getAmountOut(y1, reserve1, reserve0));
        }
        
        require(y2 > x && y2 - x > limit, "No profit");

        bytes memory data = abi.encode(uint(x) << 112 | y1, uint(flag) << 112 | y2, pair0, token);

        uint amount0;
        uint amount1;
        
        if (flag & 1 == 0) {
            if (Constants.WRAPPED_TRX < token) {
                (amount0, amount1) = (y2, 0);
            } else {
                (amount0, amount1) = (0, y2);
            }
        } else {
            if (Constants.WRAPPED_TRX < token) {
                (amount0, amount1) = (0, y1);
            } else {
                (amount0, amount1) = (y1, 0);
            }
        }

        IUniswapV2Pair(pair1).swap(amount0, amount1, address(this), data);
    }
    
    function run2(address pair0, address pair1, address pair2, address token0, address token1, uint reserve) external {
        
        require(pair0 != address(0), "Invalid Pair");
        require(pair1 != address(0), "Invalid pair");
        require(pair2 != address(0), "Invalid pair");
        
        uint112 x = uint112(reserve);
        uint112 limit = uint112(reserve >> 112);
        uint8 flag = uint8(reserve >> 224);
        
        // flag  00 : pair2 pair0
        
        uint y1;
        {
            uint reserve0;
            uint reserve1;
            
            if (flag & 1 == 0) {
                reserve0 = pair0.balance;
                reserve1 = IERC20(token0).balanceOf(pair0);
            } else {
                (reserve0, reserve1, ) = IUniswapV2Pair(pair0).getReserves();
                
                if (token0 < Constants.WRAPPED_TRX) {
                    (reserve0, reserve1) = (reserve1, reserve0);
                }
            }
            y1 = uint112(UniswapUtil.getAmountOut(x, reserve0, reserve1));
        }

        uint y2;        
        {
            uint reserve2;
            uint reserve3;
            (reserve2, reserve3, ) = IUniswapV2Pair(pair1).getReserves();
            
            if (token1 < token0) {
                (reserve2, reserve3) = (reserve3, reserve2);
            }
            y2 = uint112(UniswapUtil.getAmountOut(y1, reserve2, reserve3));
        }
        
        uint y3;
        {
            uint reserve4;
            uint reserve5;
            if (flag & 2 == 0) {
                reserve4 = IERC20(token1).balanceOf(pair2);
                reserve5 = pair2.balance;
            } else {
                (reserve4, reserve5, ) = IUniswapV2Pair(pair2).getReserves();
                
                if (Constants.WRAPPED_TRX < token1) {
                    (reserve5, reserve4) = (reserve4, reserve5);
                }
            }
            y3 = uint112(UniswapUtil.getAmountOut(y2, reserve4, reserve5));
        }
        
        require(y3 > x && y3 > limit, "No profit");
        
        bytes memory data = abi.encode(uint(x) << 112 | y1, uint(flag) << 224 | uint(y2) << 112 | y3, pair0, pair2, token0, token1);
        uint amount0;
        uint amount1;
        (amount0, amount1) = (token0 < token1) ? (uint(0), y2) : (y2, uint(0));
        
        IUniswapV2Pair(pair1).swap(amount0, amount1, address(this), data);
    }
    
    function approve(address token, address spender, uint amount) internal {
        uint allowance = IERC20(token).allowance(address(this), spender);
        
        if (allowance < amount) {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }
    
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) override external {
        
        require(sender == address(this), "Invalid sender");
        
        uint amount = amount0 + amount1;

        if (data.length == 128) {
            // run1
            uint x;
            uint y1;
            uint y2;
            address pair;
            address token;
            uint8 flag;
            uint d1;
            uint d2;
            (d1, d2, pair, token) = abi.decode(data, (uint, uint, address, address));
            x = uint112(d1 >> 112);
            y1 = uint112(d1);
            y2 = uint112(d2);
            flag = uint8(d2 >> 112);
            
            if (flag & 1 == 0) {
                require(amount >= y2, "Fee token");
                IWETH(Constants.WRAPPED_TRX).withdraw(x);
                require(address(this).balance >= x, "TRX");
                IUniswapV1Exchange(pair).trxToTokenTransferInput{value: x}(y1, block.timestamp, msg.sender);
            } else {
                require(amount >= y1, "Fee token");
                IERC20(token).approve(pair, y1);
                IUniswapV1Exchange(pair).tokenToTrxSwapInput(y1, y2, block.timestamp);
                IWETH(Constants.WRAPPED_TRX).deposit{value: y2}();
                IERC20(Constants.WRAPPED_TRX).transfer(msg.sender, x);
            }
        }
        else if (data.length == 192) {
            // run2
            uint d1;
            uint d2;
            address pair0;
            address pair2;
            address token0;
            address token1;
            
            (d1, d2, pair0, pair2, token0, token1) = abi.decode(data, (uint, uint, address, address, address, address));
            uint x = uint112(d1 >> 112);
            uint y1 = uint112(d1);
            uint y2 = uint112(d2 >> 112);
            uint y3 = uint112(d2);
            uint8 flag = uint8(d2 >> 224);
            
            require(amount >= y2, "Fee token");
            
            if (flag & 2 == 0) {
                IERC20(token1).approve(pair2, y2);
                IUniswapV1Exchange(pair2).tokenToTrxSwapInput(y2, y3, block.timestamp);
            } else {
                IERC20(token1).transfer(pair2, y2);
                uint amountOut0;
                uint amountOut1;
                (amountOut0, amountOut1) = (token1 < Constants.WRAPPED_TRX) ? (uint(0), y3) : (y3, uint(0));
                
                IUniswapV2Pair(pair2).swap(amountOut0, amountOut1, address(this), new bytes(0));
            }
            
            if (flag == 0) {
                IWETH(Constants.WRAPPED_TRX).deposit{value: y3 - x}();
            } else if (flag == 1) {
                IWETH(Constants.WRAPPED_TRX).deposit{value: y3}();
            } else if (flag == 2) {
                IWETH(Constants.WRAPPED_TRX).withdraw(x);
            }
            
            if (flag & 1 == 0) {
                IUniswapV1Exchange(pair0).trxToTokenTransferInput{value: x}(y1, block.timestamp, msg.sender);
            } else {
                IERC20(Constants.WRAPPED_TRX).transfer(pair0, x);
                uint amountOut0;
                uint amountOut1;
                (amountOut0, amountOut1) = (Constants.WRAPPED_TRX < token0) ? (uint(0), y1) : (y1, uint(0));
                
                IUniswapV2Pair(pair0).swap(amountOut0, amountOut1, msg.sender, new bytes(0));
            }
        }
        else {
            revert();
        }
        
    }

    receive() external payable {}
}