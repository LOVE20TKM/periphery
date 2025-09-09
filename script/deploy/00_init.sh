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

# ------ dont change below ------

network_dir="../network/$network"

source $network_dir/.account && \
source $network_dir/network.params && \
source $network_dir/DataViewer.params

## Using keystore file method
forge_script() {
  forge script "$@" \
    --rpc-url $RPC_URL \
    --account $KEYSTORE_ACCOUNT \
    --sender $ACCOUNT_ADDRESS \
    --password $KEYSTORE_PASSWORD \
    --gas-price 5000000000 \
    --gas-limit 50000000 \
    --broadcast \
    --legacy \
    $([[ "$network" != "anvil" ]] && [[ "$network" != thinkium* ]] && echo "--verify --etherscan-api-key $ETHERSCAN_API_KEY")
}
echo "forge_script() loaded"

# print success info
echo -e "\033[32mSuccess:\033[0m Deployed on $network"

# todo: check the deploy result
