#  ------ set base_dir before run this script ------ 
network="anvil"
# network="bsc.testnet"


# --------------------------------------------------
base_dir="../network/$network"

source "$base_dir/.account"
source "$base_dir/address.params"
source "$base_dir/network.params"
source "$base_dir/LOVE20.params"


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
        --private-key "$PRIVATE_KEY"
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
        --private-key "$PRIVATE_KEY"
}
echo "cast_call() loaded"

check_equal(){
    local msg=$1
    local expected=$2
    local actual=$3

    # check msg, expected, actual are set
    if [ -z "$msg" ] || [ -z "$expected" ] || [ -z "$actual" ]; then
        echo "Error: need 3 args: msg, expected, actual"
    fi

    if [ "$expected" != "$actual" ]; then
        echo "(failed) $msg: $expected != $actual"
    else
        echo "  (passed) $msg: $expected == $actual"
    fi
}
echo "check_equal() loaded"