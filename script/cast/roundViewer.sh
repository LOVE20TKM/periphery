#!/usr/bin/env bash

ROUND=${ROUND:-7}
ACTION_ID=${ACTION_ID:-0}
START_INDEX=${START_INDEX:-0}
END_INDEX=${END_INDEX:-10}

echo "Params：ROUND=$ROUND, ACTION_ID=$ACTION_ID, START_INDEX=$START_INDEX, END_INDEX=$END_INDEX"

echo "\n[1] actionInfosByPage($tokenAddress, ${START_INDEX}, ${END_INDEX})"
cast_call $roundViewerAddress "actionInfosByPage(address,uint256,uint256)((uint256,address,uint256,uint256,uint256,address,string,string,string[],string[])[])" $tokenAddress $START_INDEX $END_INDEX

echo "\n[2] actionSubmits($tokenAddress, $ROUND)"
cast_call $roundViewerAddress "actionSubmits(address,uint256)((address,uint256)[])" $tokenAddress $ROUND

echo "\n[3] votesNums($tokenAddress, $ROUND)"
cast_call $roundViewerAddress "votesNums(address,uint256)(uint256[],uint256[])" $tokenAddress $ROUND

echo "\n[4] votingActions($tokenAddress, $ROUND, $ACCOUNT_ADDRESS)"
cast_call $roundViewerAddress \
  "votingActions(address,uint256,address)((uint256,address,uint256,uint256,uint256,address,string,string,string[],string[],address,uint256,uint256)[])" \
  $tokenAddress $ROUND $ACCOUNT_ADDRESS

echo "\n[5] joinableActions($tokenAddress, $ROUND, $ACCOUNT_ADDRESS)"
cast_call $roundViewerAddress \
  "joinableActions(address,uint256,address)((uint256,address,uint256,uint256,uint256,address,string,string,string[],string[],uint256,bool,uint256,uint256)[])" \
  $tokenAddress $ROUND $ACCOUNT_ADDRESS

echo "\n[6] joinedActions($tokenAddress, $ACCOUNT_ADDRESS)"
cast_call $roundViewerAddress \
  "joinedActions(address,address)((uint256,address,uint256,uint256,uint256,address,string,string,string[],string[],uint256,uint256,bool,uint256)[])" \
  $tokenAddress $ACCOUNT_ADDRESS

echo "\n[7] verifyingActions($tokenAddress, $ROUND, $ACCOUNT_ADDRESS)"
cast_call $roundViewerAddress \
  "verifyingActions(address,uint256,address)((uint256,address,uint256,uint256,uint256,address,string,string,string[],string[],uint256,uint256,uint256,uint256)[])" \
  $tokenAddress $ROUND $ACCOUNT_ADDRESS

echo "\n[8] verifyingActionsByAccount($tokenAddress, $ROUND, $ACCOUNT_ADDRESS)"
cast_call $roundViewerAddress \
  "verifyingActionsByAccount(address,uint256,address)((uint256,address,uint256,uint256,uint256,address,string,string,string[],string[],uint256,uint256,uint256)[])" \
  $tokenAddress $ROUND $ACCOUNT_ADDRESS

echo "\n[9] verifiedAddressesByAction($tokenAddress, $ROUND, $ACTION_ID)"
cast_call $roundViewerAddress \
  "verifiedAddressesByAction(address,uint256,uint256)((address,uint256,uint256,uint256)[])" \
  $tokenAddress $ROUND $ACTION_ID

echo "\n[10] verificationInfosByAction($tokenAddress, $ROUND, $ACTION_ID)"
cast_call $roundViewerAddress \
  "verificationInfosByAction(address,uint256,uint256)((address,string[])[])" \
  $tokenAddress $ROUND $ACTION_ID

echo "\n[11] verificationInfosByAccount($tokenAddress, $ACTION_ID, $ACCOUNT_ADDRESS)"
cast_call $roundViewerAddress \
  "verificationInfosByAccount(address,uint256,address)(string[],string[])" \
  $tokenAddress $ACTION_ID $ACCOUNT_ADDRESS

echo "\n[12] govRewardsByAccountByRounds($tokenAddress, $ACCOUNT_ADDRESS, 0, $ROUND)"
cast_call $roundViewerAddress \
  "govRewardsByAccountByRounds(address,address,uint256,uint256)((uint256,uint256,bool)[])" \
  $tokenAddress $ACCOUNT_ADDRESS 0 $ROUND

echo "\n[13] actionRewardsByAccountByActionIdByRounds($tokenAddress, $ACCOUNT_ADDRESS, $ACTION_ID, 0, $ROUND)"
cast_call $roundViewerAddress \
  "actionRewardsByAccountByActionIdByRounds(address,address,uint256,uint256,uint256)((uint256,uint256,bool)[])" \
  $tokenAddress $ACCOUNT_ADDRESS $ACTION_ID 0 $ROUND

echo "\n[14] estimatedActionRewardOfCurrentRound($tokenAddress)"
cast_call $roundViewerAddress "estimatedActionRewardOfCurrentRound(address)(uint256)" $tokenAddress

echo "\n[15] estimatedGovRewardOfCurrentRound($tokenAddress)"
cast_call $roundViewerAddress "estimatedGovRewardOfCurrentRound(address)(uint256)" $tokenAddress

echo "\n[16] govData($tokenAddress)"
cast_call $roundViewerAddress \
  "govData(address)((uint256,uint256,uint256,uint256,uint256,uint256))" \
  $tokenAddress

echo "\n[17] tokenStatistics($tokenAddress)"
cast_call $roundViewerAddress \
  "tokenStatistics(address)((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))" \
  $tokenAddress

