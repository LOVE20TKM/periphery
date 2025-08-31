#!/usr/bin/env bash

tokenAmount=100
parentTokenAmount=100
tokenAmountMin=$(echo "$tokenAmount * 0.95" | bc)
parentTokenAmountMin=$(echo "$parentTokenAmount * 0.95" | bc)
promisedWaitingPhases=1

# echo
echo "firstTokenAddress: $firstTokenAddress"
echo "tokenAmount: $tokenAmount"
echo "parentTokenAmount: $parentTokenAmount"
echo "tokenAmountMin: $tokenAmountMin"
echo "parentTokenAmountMin: $parentTokenAmountMin"
echo "promisedWaitingPhases: $promisedWaitingPhases"
echo "to: $ACCOUNT_ADDRESS"

# approve
cast_send $firstTokenAddress "approve(address,uint256)" $love20HubAddress $(echo "$tokenAmount*1000" | bc)
cast_send $parentTokenAddress "approve(address,uint256)" $love20HubAddress $(echo "$parentTokenAmount*1000" | bc)

# allowance
parentTokenAddress=$(cast_call $firstTokenAddress "parentTokenAddress()(address)")
echo "parentTokenAddress(decoded): $parentTokenAddress"

echo "(owner=$ACCOUNT_ADDRESS, spender=$love20HubAddress)"
echo "- token($tokenAddress) allowance:"
cast_call $tokenAddress "allowance(address,address)(uint256)" $ACCOUNT_ADDRESS $love20HubAddress
echo "- parentToken($parentTokenAddress) allowance:"
cast_call $parentTokenAddress "allowance(address,address)(uint256)" $ACCOUNT_ADDRESS $love20HubAddress

# cast_send $love20HubAddress \
#   "stakeLiquidity(address,uint256,uint256,uint256,uint256,uint256,address)" \
#   $firstTokenAddress \
#   $tokenAmount \
#   $parentTokenAmount \
#   $tokenAmountMin \
#   $parentTokenAmountMin \
#   $promisedWaitingPhases \
#   $ACCOUNT_ADDRESS




