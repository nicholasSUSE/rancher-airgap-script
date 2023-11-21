#!/bin/bash
set -e
sudo echo -e "Sudo permissions acquired"

source scripts/infra.sh
source scripts/step_1.sh
source scripts/step_2.sh
source scripts/step_3.sh
source scripts/step_4.sh

# Utils
L="..."
SCRIPT_DIR=$(pwd)
BUILD_FOLDER=$SCRIPT_DIR/build
ASSETS_FOLDER=$SCRIPT_DIR/assets

# Compatibility Matrix
CERT_MANAGER_VERSION="1.12.3"
RANCHER_VERSION="2.7.5"
K3S_VERSION="v1.25.9+k3s1"

# K3s Assets
K3S_AIRGAP_IMAGE_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-airgap-images-${ARCH}.tar"
K3S_BIN_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s"
K3S_IMAGES_TXT_URL="https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-images.txt"
K3S_INSTALL_SCRIPT_URL="https://get.k3s.io"

# Rancher Assets
RANCHER_IMAGES_TXT_URL="https://github.com/rancher/rancher/releases/download/v${RANCHER_VERSION}/rancher-images.txt"
RANCHER_LOAD_IMAGES_URL="https://github.com/rancher/rancher/releases/download/v${RANCHER_VERSION}/rancher-load-images.sh"
RANCHER_SAVE_IMAGES_URL="https://github.com/rancher/rancher/releases/download/v${RANCHER_VERSION}/rancher-save-images.sh"
#-------------------------
HOSTNAME="localhost"
ARCH="amd64"

# Docker Configuration
DOCKER_PORT="5000"
DOCKER_PVT_REGISTRY_CONTAINER_NAME="localregistry"
DOCKER_PVT_REGISTRY_IMAGE="registry:2"
DOCKER_PVT_REGISTRY_HOST_PORT="$HOSTNAME:$DOCKER_PORT" # <REGISTRY.YOURDOMAIN.COM:PORT>
DOCKER_VOLUME_PVT_REGISTRY_PATH="$SCRIPT_DIR/docker_volume"

# K3S Configuration
K3S_BIN_PATH="/usr/local/bin/"
K3S_YAML_FILE="/etc/rancher/k3s/k3s.yaml"
K3S_IMAGES_DIR="/var/lib/rancher/k3s/agent/images/"
K3S_REGISTRY="/etc/rancher/k3s/registries.yaml"
K3S_REG_YAML="
mirrors:
  $DOCKER_PVT_REGISTRY_HOST_PORT:
    endpoint:
      - http://$DOCKER_PVT_REGISTRY_HOST_PORT
"


function full_exec() {
    step_1
    step_2
    step_3
    step_4
}

function distinct_exec() {

    read -p "Execute Step 1? yes[y]/[enter]): " user_input
    if [[ "$user_input" == "yes" ||  "$user_input" == "y" ]]; then
        step_1
        echo "step_1 completed."
    else
        echo "Continuing without step_1."
    fi

    read -p "Execute Step 2? yes[y]/[enter]): " user_input
    if [[ "$user_input" == "yes" ||  "$user_input" == "y" ]]; then
        step_2
        echo "step_2 completed."
    else
        echo "Continuing without step_2."
    fi

    read -p "Execute Step 3? yes[y]/[enter]): " user_input
    if [[ "$user_input" == "yes" ||  "$user_input" == "y" ]]; then
        step_3
        echo "step_3 completed."
    else
        echo "Continuing without step_3."
    fi


    read -p "Execute Step 4? yes[y]/[enter]): " user_input
    if [[ "$user_input" == "yes" ||  "$user_input" == "y" ]]; then
        step_4
        echo "step_4 completed."
    else
        echo "Continuing without step_4."
    fi
}

function exec() {

        clear
    echo "Select an option:"
    echo "____________________________________________________________________________________________________________________________________"
    select choice in "Restart from Scratch" "Full Execution" "Distinct Execution"; do
        case $choice in
            "Restart from Scratch")
                restart_from_scratch
                break
                ;;
            "Full Execution")
                full_exec
                break
                ;;
            "Distinct Execution")
                distinct_exec
                break
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
    echo "____________________________________________________________________________________________________________________________________"
}

exec