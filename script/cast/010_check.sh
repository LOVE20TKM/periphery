echo "-------------------- params check --------------------"

# address.params
check_equal "tokenViewer: launchAddress" $launchAddress $(cast_call $tokenViewerAddress "launchAddress()(address)")
check_equal "tokenViewer: stakeAddress" $stakeAddress $(cast_call $tokenViewerAddress "stakeAddress()(address)")
check_equal "tokenViewer: submitAddress" $submitAddress $(cast_call $tokenViewerAddress "submitAddress()(address)")
check_equal "tokenViewer: voteAddress" $voteAddress $(cast_call $tokenViewerAddress "voteAddress()(address)")
check_equal "tokenViewer: joinAddress" $joinAddress $(cast_call $tokenViewerAddress "joinAddress()(address)")
check_equal "tokenViewer: verifyAddress" $verifyAddress $(cast_call $tokenViewerAddress "verifyAddress()(address)")
check_equal "tokenViewer: mintAddress" $mintAddress $(cast_call $tokenViewerAddress "mintAddress()(address)")

check_equal "tokenViewer: launchAddress" $launchAddress $(cast_call $roundViewerAddress "launchAddress()(address)")
check_equal "roundViewer: stakeAddress" $stakeAddress $(cast_call $roundViewerAddress "stakeAddress()(address)")
check_equal "roundViewer: submitAddress" $submitAddress $(cast_call $roundViewerAddress "submitAddress()(address)")
check_equal "roundViewer: voteAddress" $voteAddress $(cast_call $roundViewerAddress "voteAddress()(address)")
check_equal "roundViewer: joinAddress" $joinAddress $(cast_call $roundViewerAddress "joinAddress()(address)")
check_equal "roundViewer: verifyAddress" $verifyAddress $(cast_call $roundViewerAddress "verifyAddress()(address)")
check_equal "roundViewer: mintAddress" $mintAddress $(cast_call $roundViewerAddress "mintAddress()(address)")

check_equal "mintViewer: stakeAddress" $stakeAddress $(cast_call $mintViewerAddress "stakeAddress()(address)")
check_equal "mintViewer: voteAddress" $voteAddress $(cast_call $mintViewerAddress "voteAddress()(address)")
check_equal "mintViewer: joinAddress" $joinAddress $(cast_call $mintViewerAddress "joinAddress()(address)")
check_equal "mintViewer: mintAddress" $mintAddress $(cast_call $mintViewerAddress "mintAddress()(address)")

check_equal "Hub: rootParentTokenAddress" $rootParentTokenAddress $(cast_call $love20HubAddress "WETHAddress()(address)")
check_equal "Hub: launchAddress" $launchAddress $(cast_call $love20HubAddress "launchAddress()(address)")
check_equal "Hub: stakeAddress" $stakeAddress $(cast_call $love20HubAddress "stakeAddress()(address)")
check_equal "Hub: submitAddress" $submitAddress $(cast_call $love20HubAddress "submitAddress()(address)")
check_equal "Hub: voteAddress" $voteAddress $(cast_call $love20HubAddress "voteAddress()(address)")
check_equal "Hub: joinAddress" $joinAddress $(cast_call $love20HubAddress "joinAddress()(address)")
check_equal "Hub: verifyAddress" $verifyAddress $(cast_call $love20HubAddress "verifyAddress()(address)")
check_equal "Hub: mintAddress" $mintAddress $(cast_call $love20HubAddress "mintAddress()(address)")