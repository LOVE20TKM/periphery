
round=7
actionId=0


echo "joinedActions"
cast_call $dataViewerAddress "joinedActions(address,address)((uint256,uint256,uint256)[])" $tokenAddress $ACCOUNT_ADDRESS

echo "verifiedAddressesByAction"
cast_call $dataViewerAddress "verifiedAddressesByAction(address,uint256,uint256)((address,uint256,uint256)[])" $tokenAddress $round $actionId

echo "verificationInfosByAction"
cast_call $dataViewerAddress "verificationInfosByAction(address,uint256,uint256)(address[],string[])" $tokenAddress $round $actionId

echo "tokenDetail"
cast_call $dataViewerAddress "tokenDetail(address)(string,string,(address,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256))" $tokenAddress

echo "tokenDetails"
cast_call $dataViewerAddress "tokenDetails(address[])(string[],string[],(address,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256)[])" "[$tokenAddress]"
