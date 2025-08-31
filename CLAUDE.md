# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Building and Testing
- **Build**: `forge build`
- **Test**: `forge test`
- **Format**: `forge fmt`
- **Gas Snapshots**: `forge snapshot`

### Running Single Tests
- Run specific test file: `forge test --match-path test/LOVE20Hub.t.sol`
- Run specific test function: `forge test --match-test testStakeLiquidity`

### Deployment
- Deploy contracts using Forge scripts in `script/deploy/` directory
- Example: `./script/deploy/01_deploy_hub.sh <network_name>`
- Network configurations are stored in `script/network/<network_name>/`

### Cast Operations
- Initialize environment: `source script/cast/000_init.sh <network_name>`
- Check contract states: `./script/cast/010_check.sh <network_name>`
- Various contract interaction scripts are available in `script/cast/`

## Project Architecture

### Core Contracts

**LOVE20Hub** (`src/LOVE20Hub.sol`)
- Main peripheral contract that serves as the entry point for user interactions
- Handles ETH-to-WETH conversion and liquidity staking operations
- Key functions:
  - `contributeFirstTokenWithETH()`: Converts ETH to WETH and contributes to token launch
  - `stakeLiquidity()`: Manages liquidity staking with optimal amount calculations
- Uses initialization pattern with `init()` function

**LOVE20TokenViewer** (`src/LOVE20TokenViewer.sol`)
- Read-only contract for querying token information and statistics
- Provides pagination support for token lists (launched, launching, participated tokens)
- Key functions:
  - `tokensByPage()`: Get tokens with pagination
  - `tokenDetail()`: Get comprehensive token information
  - `tokenPairInfoWithAccount()`: Get pair reserves and user balances

**LOVE20RoundViewer** (`src/LOVE20RoundViewer.sol`)
- Complex read-only contract for governance and voting data
- Handles action submissions, voting, verification, and reward calculations
- Key functionalities:
  - Action management: submission history, voting status
  - Reward calculations: governance rewards, action rewards by round
  - Verification system: scoring and verification info management
  - Statistics: comprehensive token stats including supply, reserves, governance data

### Interface Architecture
- All contracts implement corresponding interfaces in `src/interfaces/`
- Interfaces follow ILOVE20[ContractName] naming convention
- External contract dependencies (Launch, Stake, Submit, Vote, Join, Verify, Mint) are accessed via interfaces

### Dependencies
- Built on Foundry framework with Solidity 0.8.17
- Integrates with Uniswap V2 (core contracts in `lib/v2-core/`)
- Uses OpenZeppelin contracts for ERC20 functionality (`lib/openzeppelin-contracts/`)

### Deployment Structure
- Contracts use proxy-like initialization pattern (not actual proxies)
- All main contracts have `initialized` boolean and `init()` function
- Network-specific parameters stored in `script/network/<network>/` directories
- Deployment scripts handle parameter loading and contract initialization

### Testing Strategy
- Test files follow `ContractName.t.sol` pattern in `test/` directory
- Tests cover both individual functions and integration scenarios
- Mock contracts available in `test/mock/` for testing dependencies

### Development Workflow
1. Use `forge build` to compile contracts
2. Run `forge test` for all tests or target specific tests
3. Deploy using network-specific scripts in `script/deploy/`
4. Interact with deployed contracts using Cast scripts in `script/cast/`
5. Use viewer contracts for read-only operations and data aggregation