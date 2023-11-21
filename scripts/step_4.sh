#!/bin/bash
set -e

function rancher-helm-repo() {
    helm repo add rancher-stable https://releases.rancher.com/server-charts/latest
    helm fetch rancher-stable/rancher --version=v$RANCHER_VERSION --destination $BUILD_FOLDER
}

function crd-cert-manager() {
    echo "crd-cert-manager"
    echo "curl -L -o $ASSETS_FOLDER/cert-manager-crd.yaml https://github.com/cert-manager/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.crds.yaml"
    curl -L -o $ASSETS_FOLDER/cert-manager-crd.yaml https://github.com/cert-manager/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.crds.yaml
    echo "kubectl create namespace cert-manager || true"
    kubectl create namespace cert-manager || true
    echo "kubectl apply -f $ASSETS_FOLDER/cert-manager-crd.yaml"
    kubectl apply -f $ASSETS_FOLDER/cert-manager-crd.yaml
    echo "helm install cert-manager $BUILD_FOLDER/cert-manager-v$CERT_MANAGER_VERSION.tgz \
        --namespace cert-manager \
        --set image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-controller \
        --set webhook.image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-webhook \
        --set cainjector.image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-cainjector \
        --set startupapicheck.image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-ctl"
    helm install cert-manager $BUILD_FOLDER/cert-manager-v$CERT_MANAGER_VERSION.tgz \
        --namespace cert-manager \
        --set image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-controller \
        --set webhook.image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-webhook \
        --set cainjector.image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-cainjector \
        --set startupapicheck.image.repository=$DOCKER_PVT_REGISTRY_HOST_PORT/quay.io/jetstack/cert-manager-ctl
}

function install_rancher() {
    echo "install_rancher"
    echo "kubectl create namespace cattle-system || true"
    kubectl create namespace cattle-system || true
    echo "helm install rancher $BUILD_FOLDER/rancher-$RANCHER_VERSION.tgz \
        --namespace cattle-system \
        --set hostname=$HOSTNAME\
        --set certmanager.version=v$CERT_MANAGER_VERSION\
        --set rancherImage=$DOCKER_PVT_REGISTRY_HOST_PORT/rancher/rancher \
        --set systemDefaultRegistry=$DOCKER_PVT_REGISTRY_HOST_PORT \
        --set useBundledSystemChart=true \
        --set ingress.tls.source=secret \
        --debug"
    helm install rancher $BUILD_FOLDER/rancher-$RANCHER_VERSION.tgz \
        --namespace cattle-system \
        --set hostname=$HOSTNAME\
        --set certmanager.version=v$CERT_MANAGER_VERSION\
        --set rancherImage=$DOCKER_PVT_REGISTRY_HOST_PORT/rancher/rancher \
        --set systemDefaultRegistry=$DOCKER_PVT_REGISTRY_HOST_PORT \
        --set useBundledSystemChart=true \
        --set ingress.tls.source=secret \
        --debug
}




function step_4() {
    echo ""
    echo "________________________________________________________________________"
    echo "$L Step 4 start"
    rancher-helm-repo
    crd-cert-manager
    install_rancher
    echo "________________________________________________________________________"
    echo "$L Step 4 END"
    echo ""

    echo "Waiting for deployment to finish"
    kubectl -n cattle-system rollout status deploy/rancher 

    echo "Port-forwarding...https://localhost:8443 should be available"
    kubectl -n cattle-system port-forward svc/rancher 8443:443
}

