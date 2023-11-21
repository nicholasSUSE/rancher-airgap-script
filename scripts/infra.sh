#!/bin/bash
set -e


function restart_from_scratch() {
    echo $SCRIPT_DIR
    cd /usr/local/bin && ./k3s-uninstall.sh || true
    echo "$(pwd)"
    cd $SCRIPT_DIR
    echo "$(pwd)"
    clear_folders || true
    clear_helm
    docker_wipeout || true
    download_rancher_assets
    refresh_k3s
    download-cert-manager-tgz
}

function clear_folders() {
        rm $BUILD_FOLDER/* || true
        rm $ASSETS_FOLDER/* || true
}

# DOCKER --------------------------------------------------------------------------------------------------
function docker_wipeout() {
    echo "$L docker_wipeout"

    echo "$L$L executing docker-fix alias..."
    sudo usermod -aG docker nick
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo systemctl restart docker
    docker login -u "nicholaslobo" -p "Nfap142857."

    container_ids=$(docker ps -aq)
    echo "$L$L docker stop all containers"
    if [ "$container_ids" ]; then
        docker stop $container_ids
    fi

    echo "$L$L docker remove all containers"
    # Check if there are containers to remove
    if [ -n "$container_ids" ]; then
        # Iterate through each container and remove it
        for container_id in $container_ids; do
            docker rm "$container_id"
        done
    else
        echo "No containers to remove."
    fi

    echo "$L$L docker remove all images with --force"
    image_ids=$(docker images -aq)
    # Check if there are images to remove
    if [ -n "$image_ids" ]; then
        # Iterate through each image and remove it
        for image_id in $image_ids; do
            docker rmi "$image_id" --force
        done
    else
        echo "No images to remove."
    fi

    echo "$L$L docker prune all volumes with --force"
    docker volume prune --force
}
# RANCHER --------------------------------------------------------------------------------------------------
function download_rancher_assets() {
    echo -e "$L Downloading rancher-load-images.sh for Rancher version: ${RANCHER_VERSION}"
    curl -L "$RANCHER_LOAD_IMAGES_URL" -o "$ASSETS_FOLDER/rancher-load-images.sh"
    sudo chmod +x $ASSETS_FOLDER/rancher-load-images.sh

    echo -e "$L Downloading rancher-save-images.sh for Rancher version: ${RANCHER_VERSION}"
    curl -L "$RANCHER_SAVE_IMAGES_URL" -o "$ASSETS_FOLDER/rancher-save-images.sh"
    sudo chmod +x $ASSETS_FOLDER/rancher-save-images.sh

    echo -e "$L Downloading rancher-images.txt for Rancher version: ${RANCHER_VERSION}"
    curl -L "$RANCHER_IMAGES_TXT_URL" -o "$ASSETS_FOLDER/rancher-images.txt"
}

# K3S --------------------------------------------------------------------------------------------------
function download_k3s_assets() {
    echo "$L Downloading k3s-images.txt for K3s Version: $K3S_VERSION"
    curl -L "$K3S_IMAGES_TXT_URL" -o "$ASSETS_FOLDER/k3s-images.txt" --compressed

    echo "$L Downloading k3s airgap images tar for K3s version: ${K3S_VERSION}"
    curl -L "$K3S_AIRGAP_IMAGE_URL" -o "$ASSETS_FOLDER/k3s-airgap-images-amd64.tar"

    echo "$L Downloading k3s binary for K3s version: ${K3S_VERSION}"
    curl -L "$K3S_BIN_URL" -o "$ASSETS_FOLDER/k3s"

    echo "$L Downloading k3s install script"
    curl -L "$K3S_INSTALL_SCRIPT_URL" -o "$ASSETS_FOLDER/install.sh"
    chmod +x "$ASSETS_FOLDER/install.sh"
}

function create_k3s_infra() {
    echo "$L$L creating /etc/rancher/k3s directory"
    sudo mkdir -p /etc/rancher/k3s || true
}

function delete_k3s_infra() {
    echo "$L$L deleting $K3S_REGISTRY file"
    sudo rm $K3S_REGISTRY
}

function prepare_k3s_images_directory() {
    sudo mkdir -p $K3S_IMAGES_DIR
    sudo cp $ASSETS_FOLDER/k3s-airgap-images-amd64.tar $K3S_IMAGES_DIR
}

function refresh_k3s() {
    delete_k3s_infra || true
    download_k3s_assets
    create_k3s_infra
    prepare_k3s_images_directory
}


# HELM --------------------------------------------------------------------------------------------------
function clear_helm() {
        helm uninstall cert-manager -n cert-manager || true
        helm uninstall rancher -n cattle-system || true
        helm repo remove jetstack || true
        helm repo remove rancher-alpha || true
        helm repo remove rancher-latest || true
        helm repo remove rancher-stable || true
}


# CERT-MANAGER --------------------------------------------------------------------------------------------------
function download-cert-manager-tgz() {
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm fetch jetstack/cert-manager \
        --version "v$CERT_MANAGER_VERSION" \
        --destination $BUILD_FOLDER
}
