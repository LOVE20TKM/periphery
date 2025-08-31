echo "-------------------- params check --------------------"

# check DataViewer.params & address.params
check_equal "tokenViewer: launchAddress" $launchAddress $(cast_call $tokenViewerAddress "launchAddress()(address)")
check_equal "tokenViewer: stakeAddress" $stakeAddress $(cast_call $tokenViewerAddress "stakeAddress()(address)")
check_equal "tokenViewer: love20HubAddress" $love20HubAddress $(cast_call $tokenViewerAddress "hubAddress()(address)")

check_equal "roundViewer: stakeAddress" $stakeAddress $(cast_call $roundViewerAddress "stakeAddress()(address)")
check_equal "roundViewer: submitAddress" $submitAddress $(cast_call $roundViewerAddress "submitAddress()(address)")
check_equal "roundViewer: voteAddress" $voteAddress $(cast_call $roundViewerAddress "voteAddress()(address)")
check_equal "roundViewer: joinAddress" $joinAddress $(cast_call $roundViewerAddress "joinAddress()(address)")
check_equal "roundViewer: verifyAddress" $verifyAddress $(cast_call $roundViewerAddress "verifyAddress()(address)")
check_equal "roundViewer: mintAddress" $mintAddress $(cast_call $roundViewerAddress "mintAddress()(address)")
