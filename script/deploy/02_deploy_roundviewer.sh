forge_script ../DeployRoundViewer.s.sol:DeployRoundViewer \
--sig "run(address,address,address,address,address,address)" \
$stakeAddress \
$submitAddress \
$voteAddress \
$joinAddress \
$verifyAddress \
$mintAddress
