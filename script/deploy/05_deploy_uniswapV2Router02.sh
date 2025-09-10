forge_script ../DeployUniswapV2.s.sol:DeployUniswapV2  \
--sig "run(address,address)" \
"$uniswapV2FactoryAddress" \
"$rootParentTokenAddress"

