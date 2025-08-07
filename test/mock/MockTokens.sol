// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Token.sol";
import "../../src/interfaces/ILOVE20SLToken.sol";
import "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/**
 * @title MockLOVE20Token
 * @dev Mock implementation of LOVE20Token interface
 */
contract MockLOVE20Token is ILOVE20Token {
    string private _symbol;
    address private _slAddress;
    address private _parentTokenAddress;

    constructor(string memory symbol_, address parentTokenAddress_) {
        _symbol = symbol_;
        _parentTokenAddress = parentTokenAddress_;
        // Create an SL token that matches the current token address
        _slAddress = address(
            new MockLOVE20SLTokenWithTokens(
                address(this), // token address
                _parentTokenAddress // parent token address
            )
        );
    }

    function name() external pure override returns (string memory) {
        return "TEST";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function parentTokenAddress() external view returns (address) {
        return _parentTokenAddress;
    }

    function slAddress() external view returns (address) {
        return _slAddress;
    }

    function stAddress() external view returns (address) {
        return address(this);
    }

    function totalSupply() external pure returns (uint256) {
        return 1000000000000000000000000;
    }

    function balanceOf(address account) external pure returns (uint256) {
        account;
        return 1000000 ether; // Return sufficient balance for testing
    }

    function allowance(
        address owner,
        address spender
    ) external pure returns (uint256) {
        owner;
        spender;
        return 1000000 ether; // Return sufficient allowance
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external pure returns (bool) {
        from;
        to;
        value;
        return true; // Always succeed for testing
    }

    function approve(
        address spender,
        uint256 value
    ) external pure returns (bool) {
        spender;
        value;
        return true; // Always succeed for testing
    }

    function transfer(address to, uint256 value) external pure returns (bool) {
        to;
        value;
        return true; // Always succeed for testing
    }

    function uniswapV2Pair() external view returns (address) {
        return address(this);
    }

    // Add missing interface methods
    function burn(uint256 amount) external pure {
        amount; // Mock implementation
    }

    function burnForParentToken(
        uint256 amount
    ) external pure returns (uint256 parentTokenAmount) {
        amount; // Mock implementation
        return amount / 2; // Return half as parent token amount for testing
    }

    function mint(address to, uint256 amount) external pure {
        to;
        amount; // Mock implementation
    }

    function mintForParentToken(
        address to,
        uint256 amount
    ) external pure returns (uint256 parentTokenAmount) {
        to;
        amount; // Mock implementation
        return amount * 2; // Return double as parent token amount for testing
    }

    // Add missing interface methods
    function maxSupply() external pure returns (uint256) {
        return 10000000 ether;
    }

    function minter() external pure returns (address) {
        return address(0x123);
    }

    function parentPool() external pure returns (uint256) {
        return 1000 ether;
    }
}

/**
 * @title MockLOVE20SLToken
 * @dev Mock implementation of LOVE20SLToken interface
 */
contract MockLOVE20SLToken is ILOVE20SLToken {
    address private _uniswapV2Pair;

    constructor() {
        _uniswapV2Pair = address(
            new MockUniswapV2Pair(
                0,
                0,
                address(0x1111111111111111111111111111111111111111),
                address(0x2222222222222222222222222222222222222222)
            )
        );
    }

    function tokenAmountsBySlAmount(
        uint256 slAmount
    ) external pure returns (uint256 tokenAmount, uint256 parentTokenAmount) {
        slAmount; // Mock implementation
        return (1000000000000000000000000, 1000000000000000000000000);
    }

    function slAmountsByTokenAmount(
        uint256 tokenAmount,
        uint256 parentTokenAmount
    ) external pure returns (uint256 slAmount) {
        tokenAmount;
        parentTokenAmount; // Mock implementation
        return 1000000000000000000000000;
    }

    function totalSupply() external pure returns (uint256) {
        return 1000000 ether;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function uniswapV2Pair() external view returns (address) {
        return _uniswapV2Pair;
    }

    function uniswapV2PairReserves()
        external
        view
        returns (uint256, uint256, uint256)
    {
        return (0, 0, block.timestamp);
    }

    function withdrawFee(address) external pure {
        // Mock implementation
    }

    function burn(
        address to
    ) external pure returns (uint256 tokenAmount, uint256 parentTokenAmount) {
        to; // Mock implementation
        return (1000, 500);
    }

    // Add missing interface methods
    function name() external pure returns (string memory) {
        return "Mock SL Token";
    }

    function symbol() external pure returns (string memory) {
        return "MSL";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 1000000 ether;
    }

    function allowance(address, address) external pure returns (uint256) {
        return 1000000 ether;
    }

    function approve(address, uint256) external pure returns (bool) {
        return true;
    }

    function minter() external pure returns (address) {
        return address(0x123);
    }

    function tokenAddress() external pure returns (address) {
        return address(0x789);
    }

    function parentTokenAddress() external pure returns (address) {
        return address(0x456);
    }

    function MAX_WITHDRAWABLE_TO_FEE_RATIO() external pure returns (uint256) {
        return 10;
    }

    function mint(address) external pure returns (uint256) {
        return 1000;
    }

    function tokenAmounts()
        external
        pure
        returns (
            uint256 tokenAmount,
            uint256 parentTokenAmount,
            uint256 feeTokenAmount,
            uint256 feeParentTokenAmount
        )
    {
        return (1000000000000000000000000, 1000000000000000000000000, 0, 0);
    }
}

/**
 * @title MockUniswapV2Pair
 * @dev IUniswapV2Pair interface mock implementation
 */
contract MockUniswapV2Pair is IUniswapV2Pair {
    uint256 private _tokenReserve;
    uint256 private _parentTokenReserve;
    address private _token0;
    address private _token1;

    constructor(
        uint256 tokenReserve,
        uint256 parentTokenReserve,
        address token0Address,
        address token1Address
    ) {
        _tokenReserve = tokenReserve;
        _parentTokenReserve = parentTokenReserve;
        _token0 = token0Address;
        _token1 = token1Address;
    }

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)
    {
        return (uint112(_tokenReserve), uint112(_parentTokenReserve), 0);
    }

    function token0() external view returns (address) {
        return _token0;
    }

    function token1() external view returns (address) {
        return _token1;
    }

    // Add all missing IUniswapV2Pair interface implementations
    function DOMAIN_SEPARATOR() external pure returns (bytes32) {
        return keccak256("MockUniswapV2Pair");
    }

    function MINIMUM_LIQUIDITY() external pure returns (uint) {
        return 1000;
    }

    function PERMIT_TYPEHASH() external pure returns (bytes32) {
        return
            keccak256(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            );
    }

    function allowance(address, address) external pure returns (uint) {
        return 1000000 ether;
    }

    function approve(address, uint) external pure returns (bool) {
        return true;
    }

    function balanceOf(address) external pure returns (uint) {
        return 1000000 ether;
    }

    function burn(address) external pure returns (uint amount0, uint amount1) {
        return (1000, 2000);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function factory() external pure returns (address) {
        return address(0x123);
    }

    function initialize(address, address) external pure {
        // Mock implementation
    }

    function kLast() external pure returns (uint) {
        return 1000000;
    }

    function mint(address) external pure returns (uint liquidity) {
        return 5000;
    }

    function name() external pure returns (string memory) {
        return "Mock LP Token";
    }

    function nonces(address) external pure returns (uint) {
        return 1;
    }

    function permit(
        address,
        address,
        uint,
        uint,
        uint8,
        bytes32,
        bytes32
    ) external pure {
        // Mock implementation
    }

    function price0CumulativeLast() external pure returns (uint) {
        return 1000000;
    }

    function price1CumulativeLast() external pure returns (uint) {
        return 2000000;
    }

    function skim(address) external pure {
        // Mock implementation
    }

    function swap(uint, uint, address, bytes calldata) external pure {
        // Mock implementation
    }

    function symbol() external pure returns (string memory) {
        return "MLP";
    }

    function sync() external pure {
        // Mock implementation
    }

    function totalSupply() external pure returns (uint) {
        return 1000000 ether;
    }

    function transfer(address, uint) external pure returns (bool) {
        return true;
    }

    function transferFrom(address, address, uint) external pure returns (bool) {
        return true;
    }
}

/**
 * @title MockERC20WithZeroParent
 * @dev Mock contract with zero parent token address
 */
contract MockERC20WithZeroParent {
    function parentTokenAddress() external pure returns (address) {
        return address(0); // Return zero address
    }
}

/**
 * @title MockERC20WithReserves
 * @dev Mock contract with custom reserves
 */
contract MockERC20WithReserves {
    uint256 private _tokenReserve;
    uint256 private _parentTokenReserve;
    address private _uniswapV2Pair;
    address private _parentTokenAddress;

    constructor(uint256 tokenReserve, uint256 parentTokenReserve) {
        _tokenReserve = tokenReserve;
        _parentTokenReserve = parentTokenReserve;
        _uniswapV2Pair = address(this);
        _parentTokenAddress = address(new MockParentToken()); // Create a new parent token instance
    }

    function parentTokenAddress() external view returns (address) {
        return _parentTokenAddress;
    }

    function slAddress() external view returns (address) {
        return address(this);
    }

    function uniswapV2Pair() external view returns (address) {
        return _uniswapV2Pair;
    }

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)
    {
        return (uint112(_tokenReserve), uint112(_parentTokenReserve), 0);
    }

    function token0() external view returns (address) {
        return address(this); // Assume this is token0
    }

    function token1() external view returns (address) {
        return _parentTokenAddress; // Parent token
    }

    // Basic ERC20 functions (simplified implementation)
    function balanceOf(address) external pure returns (uint256) {
        return 1000000 ether; // Return sufficient balance
    }

    function allowance(address, address) external pure returns (uint256) {
        return 1000000 ether; // Return sufficient allowance
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure returns (bool) {
        return true; // Always succeed
    }

    function approve(address, uint256) external pure returns (bool) {
        return true; // Always succeed
    }
}

/**
 * @title MockParentToken
 * @dev Mock implementation of parent token
 */
contract MockParentToken {
    // Basic ERC20 functions (simplified implementation)
    function balanceOf(address) external pure returns (uint256) {
        return 1000000 ether; // Return sufficient balance
    }

    function allowance(address, address) external pure returns (uint256) {
        return 1000000 ether; // Return sufficient allowance
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure returns (bool) {
        return true; // Always succeed
    }

    function approve(address, uint256) external pure returns (bool) {
        return true; // Always succeed
    }
}

/**
 * @title MockLOVE20SLTokenWithTokens
 * @dev Mock implementation of LOVE20SLToken interface with specific token address
 */
contract MockLOVE20SLTokenWithTokens is ILOVE20SLToken {
    address private _uniswapV2Pair;
    address private _tokenAddress;
    address private _parentTokenAddress;

    constructor(address tokenAddr, address parentTokenAddr) {
        _tokenAddress = tokenAddr;
        _parentTokenAddress = parentTokenAddr;
        _uniswapV2Pair = address(
            new MockUniswapV2Pair(0, 0, tokenAddr, parentTokenAddr)
        );
    }

    function tokenAmountsBySlAmount(
        uint256 slAmount
    ) external pure returns (uint256 tokenAmount, uint256 parentTokenAmount) {
        slAmount; // Mock implementation
        return (1000000000000000000000000, 1000000000000000000000000);
    }

    function slAmountsByTokenAmount(
        uint256 tokenAmount,
        uint256 parentTokenAmount
    ) external pure returns (uint256 slAmount) {
        tokenAmount;
        parentTokenAmount; // Mock implementation
        return 1000000000000000000000000;
    }

    function totalSupply() external pure returns (uint256) {
        return 1000000 ether;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function uniswapV2Pair() external view returns (address) {
        return _uniswapV2Pair;
    }

    function uniswapV2PairReserves()
        external
        view
        returns (uint256, uint256, uint256)
    {
        return (0, 0, block.timestamp);
    }

    function withdrawFee(address) external pure {
        // Mock implementation
    }

    function burn(
        address to
    ) external pure returns (uint256 tokenAmount, uint256 parentTokenAmount) {
        to; // Mock implementation
        return (1000, 500);
    }

    // Add missing interface methods
    function name() external pure returns (string memory) {
        return "Mock SL Token";
    }

    function symbol() external pure returns (string memory) {
        return "MSL";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 1000000 ether;
    }

    function allowance(address, address) external pure returns (uint256) {
        return 1000000 ether;
    }

    function approve(address, uint256) external pure returns (bool) {
        return true;
    }

    function minter() external pure returns (address) {
        return address(0x123);
    }

    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function parentTokenAddress() external view returns (address) {
        return _parentTokenAddress;
    }

    function MAX_WITHDRAWABLE_TO_FEE_RATIO() external pure returns (uint256) {
        return 10;
    }

    function mint(address) external pure returns (uint256) {
        return 1000;
    }

    function tokenAmounts()
        external
        pure
        returns (
            uint256 tokenAmount,
            uint256 parentTokenAmount,
            uint256 feeTokenAmount,
            uint256 feeParentTokenAmount
        )
    {
        return (1000000000000000000000000, 1000000000000000000000000, 0, 0);
    }
}
