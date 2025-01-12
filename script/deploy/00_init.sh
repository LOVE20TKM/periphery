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

forge_script() {
    forge script "$@" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    $([ "$network" != "anvil" ] && echo "--verify --etherscan-api-key $ETHERSCAN_API_KEY")
}

# 打印成功信息，并输出当前网络
echo -e "\033[32mSuccess:\033[0m Deployed on $network"