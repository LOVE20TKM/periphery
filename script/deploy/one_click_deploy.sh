#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$script_dir" || exit 1

extract_deployed_address() {
    local deploy_output="$1"
    local label="$2"

    printf '%s\n' "$deploy_output" \
        | sed -nE "s/^.*${label}[^0-9a-fA-F]*(0x[0-9a-fA-F]{40}).*$/\1/p" \
        | tail -n 1
}

deploy_and_record_address() {
    local script_path="$1"
    local label="$2"
    local address_var="$3"
    local display_name="$4"
    local deploy_output
    local deploy_output_file
    local deploy_status
    local deployed_address

    deploy_output_file=$(mktemp) || return 1
    source "$script_path" 2>&1 | tee "$deploy_output_file"
    deploy_status=${PIPESTATUS[0]}
    deploy_output=$(<"$deploy_output_file")
    rm -f "$deploy_output_file"

    if [ "$deploy_status" -ne 0 ]; then
        echo -e "\033[31mError:\033[0m $display_name deployment failed"
        return 1
    fi

    deployed_address=$(extract_deployed_address "$deploy_output" "$label")
    if [ -z "$deployed_address" ]; then
        echo -e "\033[31mError:\033[0m Failed to capture $display_name deployed address"
        return 1
    fi

    printf -v "$address_var" '%s' "$deployed_address"
}

require_address_param() {
    local param_name="$1"
    local param_value="${!param_name}"

    if [[ ! "$param_value" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
        echo -e "\033[31mError:\033[0m $param_name is missing or invalid: $param_value"
        return 1
    fi
}

validate_required_address_params() {
    local param_name

    for param_name in \
        rootParentTokenAddress \
        uniswapV2FactoryAddress \
        launchAddress \
        stakeAddress \
        submitAddress \
        voteAddress \
        joinAddress \
        verifyAddress \
        mintAddress
    do
        require_address_param "$param_name" || return 1
    done
}

require_contract_code() {
    local param_name="$1"
    local param_value="${!param_name}"
    local contract_code
    local cast_error_file
    local cast_status

    cast_error_file=$(mktemp) || return 1
    contract_code=$(cast code --rpc-url "$RPC_URL" "$param_value" 2>"$cast_error_file")
    cast_status=$?
    if [ "$cast_status" -ne 0 ]; then
        echo -e "\033[31mError:\033[0m Failed to fetch bytecode for $param_name at $param_value"
        cat "$cast_error_file"
        rm -f "$cast_error_file"
        return 1
    fi
    rm -f "$cast_error_file"

    contract_code=$(printf '%s' "$contract_code" | tr -d '[:space:]')
    if [ -z "$contract_code" ] || [ "$contract_code" = "0x" ]; then
        echo -e "\033[31mError:\033[0m $param_name at $param_value has no deployed bytecode"
        return 1
    fi
}

validate_required_contract_code() {
    local param_name

    if [ "$network" != "anvil" ]; then
        return 0
    fi

    for param_name in \
        rootParentTokenAddress \
        uniswapV2FactoryAddress \
        launchAddress \
        stakeAddress \
        submitAddress \
        voteAddress \
        joinAddress \
        verifyAddress \
        mintAddress
    do
        require_contract_code "$param_name" || return 1
    done
}

write_address_params() {
    local params_file="$network_dir/address.params"
    local params_tmp

    params_tmp=$(mktemp "${params_file}.tmp.XXXXXX") || return 1
    if [ -f "$params_file" ]; then
        awk \
            -v tokenViewerAddress="$tokenViewerAddress" \
            -v roundViewerAddress="$roundViewerAddress" \
            -v mintViewerAddress="$mintViewerAddress" \
            -v love20HubAddress="$love20HubAddress" \
            -v uniswapV2Router02Address="$uniswapV2Router02Address" '
            BEGIN {
                values["tokenViewerAddress"] = tokenViewerAddress
                values["roundViewerAddress"] = roundViewerAddress
                values["mintViewerAddress"] = mintViewerAddress
                values["love20HubAddress"] = love20HubAddress
                values["uniswapV2Router02Address"] = uniswapV2Router02Address
                order[1] = "tokenViewerAddress"
                order[2] = "roundViewerAddress"
                order[3] = "mintViewerAddress"
                order[4] = "love20HubAddress"
                order[5] = "uniswapV2Router02Address"
            }
            {
                key = $0
                sub(/=.*/, "", key)
                gsub(/^[[:space:]]+/, "", key)
                gsub(/[[:space:]]+$/, "", key)
                if ($0 ~ /^[[:space:]]*($|#)/) {
                    print $0
                } else if ($0 ~ /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=/ && key in values) {
                    print key "=" values[key]
                    seen[key] = 1
                } else if ($0 ~ /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=[A-Za-z0-9_:.\/-]*[[:space:]]*$/) {
                    print $0
                } else {
                    print "Warning: skipping invalid address.params line " NR ": " $0 > "/dev/stderr"
                }
            }
            END {
                for (i = 1; i <= 5; i++) {
                    key = order[i]
                    if (!(key in seen)) {
                        print key "=" values[key]
                    }
                }
            }
        ' "$params_file" > "$params_tmp"
    else
        {
            printf 'tokenViewerAddress=%s\n' "$tokenViewerAddress"
            printf 'roundViewerAddress=%s\n' "$roundViewerAddress"
            printf 'mintViewerAddress=%s\n' "$mintViewerAddress"
            printf 'love20HubAddress=%s\n' "$love20HubAddress"
            printf 'uniswapV2Router02Address=%s\n' "$uniswapV2Router02Address"
        } > "$params_tmp"
    fi

    if [ $? -ne 0 ]; then
        rm -f "$params_tmp"
        return 1
    fi

    mv "$params_tmp" "$params_file"
}

export network=$1
if [ -z "$network" ] || [ ! -d "../network/$network" ]; then
    echo -e "\033[31mError:\033[0m Network parameter is required."
    echo -e "\nAvailable networks:"
    for net in $(ls ../network); do
        echo "  - $net"
    done
    exit 1
fi

echo -e "\n[Step 1/6] Initializing environment..."
source 00_init.sh "$network"
if [ $? -ne 0 ]; then
    echo -e "\033[31mError:\033[0m Failed to initialize environment"
    exit 1
fi

validate_required_address_params
if [ $? -ne 0 ]; then
    exit 1
fi

validate_required_contract_code
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e "\n========================================="
echo -e "  One-Click Deploy Periphery"
echo -e "  Network: $network"
echo -e "========================================="

echo -e "\n[Step 2/6] Deploying LOVE20TokenViewer..."
deploy_and_record_address 01_deploy_tokenviewer.sh "TokenViewer deployed at" tokenViewerAddress "LOVE20TokenViewer"
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e "\n[Step 3/6] Deploying LOVE20RoundViewer..."
deploy_and_record_address 02_deploy_roundviewer.sh "RoundViewer deployed at" roundViewerAddress "LOVE20RoundViewer"
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e "\n[Step 4/6] Deploying LOVE20MintViewer..."
deploy_and_record_address 03_deploy_mintviewer.sh "MintViewer deployed at" mintViewerAddress "LOVE20MintViewer"
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e "\n[Step 5/6] Deploying LOVE20Hub..."
deploy_and_record_address 04_deploy_hub.sh "Hub contract deployed, address:" love20HubAddress "LOVE20Hub"
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e "\n[Step 6/6] Deploying UniswapV2Router02..."
deploy_and_record_address 05_deploy_uniswapV2Router02.sh "uniswapV2Router02Address:" uniswapV2Router02Address "UniswapV2Router02"
if [ $? -ne 0 ]; then
    exit 1
fi

write_address_params
if [ $? -ne 0 ]; then
    echo -e "\033[31mError:\033[0m Failed to write $network_dir/address.params"
    exit 1
fi

echo -e "\n========================================="
echo -e "\033[32m✓ Deployment completed successfully!\033[0m"
echo -e "========================================="
echo -e "TokenViewer Address: $tokenViewerAddress"
echo -e "RoundViewer Address: $roundViewerAddress"
echo -e "MintViewer Address: $mintViewerAddress"
echo -e "Hub Address: $love20HubAddress"
echo -e "UniswapV2Router02 Address: $uniswapV2Router02Address"
echo -e "Network: $network"
echo -e "=========================================\n"
