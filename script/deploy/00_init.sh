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

## used for thinkium801
forge_script() {
  forge script "$@" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --gas-price 5000000000 \
    --gas-limit 50000000 \
    --broadcast \
    --legacy \
    $([ "$network" != "anvil" ] && [ "$network" != "thinkium801" ] && [ "$network" != "thinkium801_dev" ]  && echo "--verify --etherscan-api-key $ETHERSCAN_API_KEY")
}
echo "forge_script() loaded"

# print success info
echo -e "\033[32mSuccess:\033[0m Deployed on $network"

# todo: check the deploy result
