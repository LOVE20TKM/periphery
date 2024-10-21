# ------ set network ------
network="anvil"
# network="bsc.testnet"

# ------ dont change below ------

network_dir="../network/$network"

source $network_dir/.account && \
source $network_dir/network.params && \
source $network_dir/DataViewer.params

forge_script() {
    forge script "$@" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    $([ "$network" != "anvil" ] && echo "--verify --etherscan-api-key $ETHERSCAN_API_KEY")
}