# ------ set network ------
network=$1
if [ -z "$network" ] || [ ! -d "../network/$network" ]; then
    echo -e "\033[31mError:\033[0m Network parameter is required."
    echo -e "\nAvailable networks:"
    for net in $(ls ../network); do
        echo "  - $net"
    done
    return 1
fi
# --------------------------------------------------
base_dir="../network/$network"

source "$base_dir/.account"
source "$base_dir/address.params"
source "$base_dir/network.params"
source "$base_dir/address.core.params"

# ------ user defined variables ------ 
tokenAddress=$firstTokenAddress # 1st token

# ------ Request keystore password ------
echo -e "\nPlease enter keystore password (for $KEYSTORE_ACCOUNT):"
read -s KEYSTORE_PASSWORD
export KEYSTORE_PASSWORD
echo "Password saved, will not be requested again in this session"

# ------ functions ------
cast_send() {
    local address=$1
    local function_signature=$2
    shift 2
    local args=("$@")

    # echo "Executing cast send: $address $function_signature ${args[@]}"
    cast send "$address" \
        "$function_signature" \
        "${args[@]}" \
        --rpc-url "$RPC_URL" \
        --account "$KEYSTORE_ACCOUNT" \
        --password "$KEYSTORE_PASSWORD" \
        --legacy
}
echo "cast_send() loaded"

cast_call() {
    local address=$1
    local function_signature=$2
    shift 2
    local args=("$@")

    # echo "Executing cast call: $address $function_signature ${args[@]}"
    cast call "$address" \
        "$function_signature" \
        "${args[@]}" \
        --rpc-url "$RPC_URL" \
        --account "$KEYSTORE_ACCOUNT" \
        --password "$KEYSTORE_PASSWORD"
}
echo "cast_call() loaded"

check_equal(){
    local msg="$1"
    local expected="$2"
    local actual="$3"

    # check params
    if [ -z "$msg" ] || [ -z "$expected" ] || [ -z "$actual" ]; then
        echo "Error: 3 params needed: msg, expected, actual"
        return 1
    fi

    # remove double quotes
    actual_clean=$(echo "$actual" | sed 's/^"//;s/"$//')


    if [ "$expected" != "$actual_clean" ]; then
        echo "(failed) $msg: $expected != $actual_clean"
    else
        echo "  (passed) $msg: $expected == $actual_clean"
    fi
}
echo "check_equal() loaded"



echo "------ user defined variables ------";
echo "tokenAddress: $tokenAddress"

echo "------ calculated variables ------";
parentTokenAddress=$(cast_call $tokenAddress "parentTokenAddress()(address)")
echo "parentTokenAddress: $parentTokenAddress"


echo "------ $base_dir/.account loaded ------";
echo "ACCOUNT_ADDRESS: $ACCOUNT_ADDRESS"

echo "------ $base_dir/network.params loaded ------";
echo "RPC_URL: $RPC_URL"

echo "------ $base_dir/address.params loaded ------";
echo "uniswapV2FactoryAddress: $uniswapV2FactoryAddress"
echo "rootParentTokenAddress: $rootParentTokenAddress"
echo "launchAddress: $launchAddress"
echo "stakeAddress: $stakeAddress"
echo "submitAddress: $submitAddress"
echo "voteAddress: $voteAddress"
echo "joinAddress: $joinAddress"
echo "randomAddress: $randomAddress"
echo "verifyAddress: $verifyAddress"
echo "mintAddress: $mintAddress"
echo "firstTokenAddress: $firstTokenAddress"
