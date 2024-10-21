forge_script ../DeployPeripheral.s.sol:DeployPeripheral \
--sig "run(address,address,address,address,address)" \
$launchAddress \
$voteAddress \
$joinAddress \
$verifyAddress \
$mintAddress
