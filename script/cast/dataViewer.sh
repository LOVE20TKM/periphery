
round=7
actionId=0


echo "tokensByPage"
cast_call $dataViewerAddress "tokensByPage(uint256,uint256)(address[])" 0 10

echo "childTokensByPage"
cast_call $dataViewerAddress "childTokensByPage(address,uint256,uint256)(address[])" $tokenAddress 0 10

echo "tokenDetailBySymbol"
tokenSymbol=$(cast_call $tokenAddress "symbol()(string)")
cast_call $dataViewerAddress "tokenDetailBySymbol(string)((address,string,string,uint256,string,address,address,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256))" "$tokenSymbol"

echo "joinedActions"
cast_call $dataViewerAddress "joinedActions(address,address)(((uint256,address,uint256),(uint256,uint256,address,string,string,string[],string[])),uint256,uint256,uint256)[]" $tokenAddress $ACCOUNT_ADDRESS

echo "verifiedAddressesByAction"
cast_call $dataViewerAddress "verifiedAddressesByAction(address,uint256,uint256)((address,uint256,uint256,uint256)[])" $tokenAddress $round $actionId

echo "verificationInfosByAction"
cast_call $dataViewerAddress "verificationInfosByAction(address,uint256,uint256)((address,string[])[])" $tokenAddress $round $actionId

echo "tokenDetail"
cast_call $dataViewerAddress "tokenDetail(address)((address,string,string,uint256,string,address,address,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256))" $tokenAddress

echo "tokenDetails"
cast_call $dataViewerAddress "tokenDetails(address[])((address,string,string,uint256,string,address,address,uint256)[],(address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256)[])" "[$tokenAddress]"
