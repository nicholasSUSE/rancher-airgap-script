#!/bin/bash
set -e


function target-rancher-images-txt() {
    mv $ASSETS_FOLDER/rancher-images.txt ../backup-rancher-images.txt
    cp $SCRIPT_DIR/target-rancher-images.txt $ASSETS_FOLDER/rancher-images.txt
}

function template-cert-manager() {
    helm template "$BUILD_FOLDER/cert-manager-v$CERT_MANAGER_VERSION.tgz" | \
            awk '$1 ~ /image:/ {print $2}' | sed s/\"//g >> $ASSETS_FOLDER/rancher-images.txt
}

function sort-unique-images() {
    sort -u $ASSETS_FOLDER/rancher-images.txt -o $ASSETS_FOLDER/rancher-images.txt
}

function save-load-images() {
    cd "$(dirname "$0")/assets"
    ./rancher-save-images.sh --image-list ./rancher-images.txt
    ./rancher-load-images.sh --image-list ./rancher-images.txt --registry $DOCKER_PVT_REGISTRY_HOST_PORT
}

function step_2() {
    echo ""
    echo "________________________________________________________________________"
    echo "$L Step 2 start"
    target-rancher-images-txt
    template-cert-manager
    sort-unique-images
    save-load-images
    echo "________________________________________________________________________"
    echo "$L Step 2 END"
    echo ""
}