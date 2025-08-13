#!/usr/bin/env bash
set -euo pipefail


# 默认分页范围，可按需修改
START_INDEX=${START_INDEX:-0}
END_INDEX=${END_INDEX:-10}

echo "\n[1] tokensByPage(${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "tokensByPage(uint256,uint256)(address[])" $START_INDEX $END_INDEX

echo "\n[2] childTokensByPage($tokenAddress, ${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "childTokensByPage(address,uint256,uint256)(address[])" $tokenAddress $START_INDEX $END_INDEX

echo "\n[3] launchingTokensByPage(${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "launchingTokensByPage(uint256,uint256)(address[])" $START_INDEX $END_INDEX

echo "\n[4] launchedTokensByPage(${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "launchedTokensByPage(uint256,uint256)(address[])" $START_INDEX $END_INDEX

echo "\n[5] launchingChildTokensByPage($parentTokenAddress, ${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "launchingChildTokensByPage(address,uint256,uint256)(address[])" $parentTokenAddress $START_INDEX $END_INDEX

echo "\n[6] launchedChildTokensByPage($parentTokenAddress, ${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "launchedChildTokensByPage(address,uint256,uint256)(address[])" $parentTokenAddress $START_INDEX $END_INDEX

echo "\n[7] participatedTokensByPage($ACCOUNT_ADDRESS, ${START_INDEX}, ${END_INDEX})"
cast_call $tokenViewerAddress "participatedTokensByPage(address,uint256,uint256)(address[])" $ACCOUNT_ADDRESS $START_INDEX $END_INDEX

echo "\n[8] tokenDetailBySymbol(symbol)"
tokenSymbol=$(cast_call $tokenAddress "symbol()(string)")
cast_call $tokenViewerAddress \
  "tokenDetailBySymbol(string)((address,string,string,uint256,address,string,string,address,address,address,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256))" \
  "$tokenSymbol"

echo "\n[9] tokenDetail($tokenAddress)"
cast_call $tokenViewerAddress \
  "tokenDetail(address)((address,string,string,uint256,address,string,string,address,address,address,uint256),(address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256))" \
  $tokenAddress

echo "\n[10] tokenDetails([$tokenAddress])"
cast_call $tokenViewerAddress \
  "tokenDetails(address[])((address,string,string,uint256,address,string,string,address,address,address,uint256)[],(address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,uint256)[])" \
  "[$tokenAddress]"

echo "\n[11] tokenPairInfoWithAccount($ACCOUNT_ADDRESS, $tokenAddress)"
cast_call $tokenViewerAddress \
  "tokenPairInfoWithAccount(address,address)((address,uint256,uint256,uint256,uint256,uint256,uint256))" \
  $ACCOUNT_ADDRESS $tokenAddress

echo "================== tokenViewer.sh done =================\n"
