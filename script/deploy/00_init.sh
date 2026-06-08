# ------ set network ------
export network=$1
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

if ! source "$network_dir/.account" || \
   ! source "$network_dir/network.params" || \
   ! source "$network_dir/address.core.params"; then
    echo -e "\033[31mError:\033[0m Failed to load network params from $network_dir"
    return 1
fi

require_env() {
    local var_name="$1"
    local var_value

    eval "var_value=\${$var_name-}"

    if [ -z "$var_value" ]; then
        echo -e "\033[31mError:\033[0m $var_name is required."
        return 1
    fi
}

validate_deploy_env() {
    require_env RPC_URL || return 1
    require_env ACCOUNT_ADDRESS || return 1

    if [ "$network" = "anvil" ]; then
        require_env PRIVATE_KEY || return 1
    else
        require_env KEYSTORE_ACCOUNT || return 1
        if [[ "$network" != thinkium* ]]; then
            require_env ETHERSCAN_API_KEY || return 1
        fi
    fi
}

validate_deploy_env || return 1

# ------ Request keystore password ------
if [ "$network" = "anvil" ]; then
    export KEYSTORE_PASSWORD="${KEYSTORE_PASSWORD:-}"
    export KEYSTORE_PASSWORD_ACCOUNT="$KEYSTORE_ACCOUNT"
    echo "Using PRIVATE_KEY from anvil .account"
else
    echo -e "\nPlease enter keystore password (for $KEYSTORE_ACCOUNT):"
    if ! read -rs KEYSTORE_PASSWORD; then
        echo -e "\033[31mError:\033[0m Failed to read keystore password."
        return 1
    fi
    export KEYSTORE_PASSWORD
    echo "Password saved, will not be requested again in this session"
fi

## Using keystore file method
forge_script() {
  if [ "$network" = "anvil" ]; then
    local anvil_build_args=()
    [ -n "$ANVIL_FOUNDRY_OUT" ] && anvil_build_args+=(--out "$ANVIL_FOUNDRY_OUT")
    [ -n "$ANVIL_FOUNDRY_CACHE" ] && anvil_build_args+=(--cache-path "$ANVIL_FOUNDRY_CACHE")

    forge script "$@" \
      --rpc-url "$RPC_URL" \
      --private-key "$PRIVATE_KEY" \
      --sender "$ACCOUNT_ADDRESS" \
      --gas-price 5000000000 \
      --gas-limit 50000000 \
      --broadcast \
      --legacy \
      "${anvil_build_args[@]}"
  else
    local verify_args=()
    if [[ "$network" != thinkium* ]]; then
      verify_args=(--verify --etherscan-api-key "$ETHERSCAN_API_KEY")
    fi

    forge script "$@" \
      --rpc-url "$RPC_URL" \
      --account "$KEYSTORE_ACCOUNT" \
      --sender "$ACCOUNT_ADDRESS" \
      --password "$KEYSTORE_PASSWORD" \
      --gas-price 5000000000 \
      --gas-limit 50000000 \
      --broadcast \
      --legacy \
      "${verify_args[@]}"
  fi
}
echo "forge_script() loaded"

# print success info
echo -e "\033[32mSuccess:\033[0m Deployed on $network"

# todo: check the deploy result
