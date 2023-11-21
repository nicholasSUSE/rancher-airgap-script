#!/bin/bash
set -e


function registry_yaml_file() {
    echo -e "....updating registry.yaml file at: $K3S_REGISTRY ..."    
    if ! echo -e "$K3S_REG_YAML" | sudo tee $K3S_REGISTRY > /dev/null; then    
        echo -e "Error: Failed to create or update $K3S_REGISTRY."        
        exit 1
    fi
}

function k3s_bin_install() {
    sudo cp --remove-destination $ASSETS_FOLDER/k3s $K3S_BIN_PATH
    chmod +x "$ASSETS_FOLDER/install.sh"
    INSTALL_K3S_VERSION=$K3S_VERSION source "$ASSETS_FOLDER/install.sh"
}

function kubectl_k3s() {
    sudo chmod 777 $K3S_YAML_FILE 
    cp --remove-destination $K3S_YAML_FILE ~/.kube/config
    kubectl cluster-info 
}


function step_3() {
    echo ""
    echo "________________________________________________________________________"
    echo "$L Step 3 start"
    registry_yaml_file
    k3s_bin_install
    kubectl_k3s
    echo "________________________________________________________________________"
    echo "$L Step 3 END"
    echo ""
}