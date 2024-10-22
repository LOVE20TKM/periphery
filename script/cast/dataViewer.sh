
round=7
actionId=0


echo "joinableActions"
cast call $dataViewerAddress "joinableActions(address,uint256)((uint256,uint256,uint256)[])" $tokenAddress $round

echo "joinedActions"
cast_call $dataViewerAddress "joinedActions(address,address)((uint256,uint256,uint256)[])" $tokenAddress $ACCOUNT_ADDRESS

echo "verifiedAddressesByAction"
cast call $dataViewerAddress "verifiedAddressesByAction(address,uint256,uint256)((address,uint256,uint256)[])" $tokenAddress $round $actionId

echo "verificationInfosByAction"
cast call $dataViewerAddress "verificationInfosByAction(address,uint256,uint256)(address[],string[])" $tokenAddress $round $actionId

echo "tokenDetail"
cast call $dataViewerAddress "tokenDetail(address)(string,string,(address,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256))" $tokenAddress

echo "tokenDetails"
cast call $dataViewerAddress "tokenDetails(address[])(string[],string[],(address,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256)[])" $tokenAddress


cast call $dataViewerAddress "tokenDetail(address)" $tokenAddress