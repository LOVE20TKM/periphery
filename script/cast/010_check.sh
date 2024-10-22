echo "-------------------- params check --------------------"

# check DataViewer.params & address.params
check_equal "dataViewer: launchAddress" $launchAddress $(cast_call $dataViewerAddress "launchAddress()(address)")
check_equal "dataViewer: voteAddress" $voteAddress $(cast_call $dataViewerAddress "voteAddress()(address)")
check_equal "dataViewer: joinAddress" $joinAddress $(cast_call $dataViewerAddress "joinAddress()(address)")
check_equal "dataViewer: verifyAddress" $verifyAddress $(cast_call $dataViewerAddress "verifyAddress()(address)")
check_equal "dataViewer: mintAddress" $mintAddress $(cast_call $dataViewerAddress "mintAddress()(address)")
