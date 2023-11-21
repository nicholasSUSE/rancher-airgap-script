# Auto Install Script Rancher Airgap with local Private Registry

##### Compatibility Matrix




##### Releases
- https://github.com/rancher/rancher/releases/download/v2.7.4/rancher-images.txt
- https://github.com/rancher/rancher/releases/download/v2.7.7-rc2/rancher-load-images.sh
- https://github.com/rancher/rancher/releases/download/v2.7.7-rc2/rancher-save-images.sh

---

# Airgap Rancher Installation

Useful links:
- [Rancher 2.7.5 Support Matrix](https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-7-5/)
- [Cert-Manager Supported Releases](https://cert-manager.io/docs/installation/supported-releases/)
- [Rancher Releases](https://github.com/rancher/rancher/releases)
- [K3s Releases](https://github.com/k3s-io/k3s/releases)

---

## Installation Outline

1. **Step_1**: Set up infrastructure and private registry
2. **Step_2**: Collect and publish images to your private registry
3. **Step_3**: Set up a Kubernetes cluster (Skip this step for Docker installations)
4. **Step_4**: Install Rancher

---

## 1. Infrastructure and Private Registry

[Set up Infrastructure and Private Registry](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/air-gapped-helm-cli-install/infrastructure-private-registry)

An air gapped environment is an environment where the Rancher server is installed offline or behind a firewall 

3 Infrastructure options: [More information](https://ranchermanager.docs.rancher.com/pages-for-subheaders/installation-and-upgrade)

- K3s Kubernetes Cluster
- RKE Kubernetes Cluster
- single Docker container

More information on the first provided link. 

### Set up a Private Image Registry 

- Rancher supports air gap installs using a private registry. 
- You must have your own private registry or other means of distributing container images to your machines. 
- In a later step, when you set up your K3s Kubernetes cluster, you will create **a private registries configuration file** with details from this registry.

#### [K3s Private Registry Configuration](https://docs.k3s.io/installation/private-registry)

- **Containerd** can be configured to connect to private registries and use them to pull private images on the node. 
- Upon startup, K3s will check to see if a `registries.yaml` file exists at `/etc/rancher/k3s/` and instruct **containerd** to use any registries defined in the file. If you wish to use a private registry, then:
- `you will need to create this file as root on each node that will be using this registry`
- **Registries Configuration File** 2 main sections:
    - mirrors
  - configs

More information on the provided link. 

##### Adding Images to the Private Registry 
1. Obtain `k3s-images.txt` file from: [K3s Releases Page](https://github.com/k3s-io/k3s/releases?expanded=true&page=8&q=v1.25.9)
    - Pull the K3s images listed on the `k3s-images.txt` file from docker.io
    - Example: `docker pull docker.io/rancher/coredns-coredns:1.6.3`
2. Retag the images to the private registry
   - Example: `docker tag rancher/coredns-coredns:1.6.3 mycustomreg.com:5000/coredns-coredns` 
3. Push the images to the private registry
    - Example: `docker push mycustomreg.com:5000/coredns-coredns`

---

## 2. Collect and Publish images to your private registry 

[Collect and Publish Images to your Private Registry](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/air-gapped-helm-cli-install/publish-images)

> How to set up your private registry so that when you install Rancher, Rancher will pull all the required images from this registry. 

- By default, all images used to **provision Kubernetes Clusters** or launch any tools in Rancher are pulled from Docker Hub. 
- In an air gapped installation of Rancher, you will need a private registry that is accessible by your Rancher server. 
- Then, you need to load the registry with all the images. 

Procedure:

1. Find the required assets for your Rancher version: [Rancher Releases Page](https://github.com/rancher/rancher/releases)
    - `rancher-images.txt` list of images needed to install Rancher, provision clusters and user Rancher tools.
    - `rancher-save-images.sh` Script to pull all images in **rancher-images.txt** from Docker Hub and save all of them as `rancher-images.tar.gz`.
    - `rancher-load-images.sh` Script to load images from **tar.gz file** file and push to the target private registry
2. Collect the **cert-manager** image:
    - In a Kubernetes install, if using Rancher **self-signed TLS certificates**, you must add the `cert-manager` image to `rancher-images.txt` as well. 
    - Fetch the latest `cert-manager` Helm chart and parse the template for image details:
        ```(bash)
        helm repo add jetstack https://charts.jetstack.io
        helm repo update
        helm fetch jetstack/cert-manager --version v1.11.0
        helm template ./cert-manager-<version>.tgz | awk '$1 ~ /image:/ {print $2}' | sed s/\"//g >> ./rancher-images.txt
        ```
    - Sort and unique the images list to remove any overlap between the sources:
        ```(bash)
        sort -u rancher-images.txt -o rancher-images.txt
        ```
3. Save the images to your workstation:
    1. Make `rancher-save-images.sh` an executable:
        ```(bash)
        chmod +x rancher-save-images.sh
        ```
    2. Run `rancher-save-images.sh` with the `rancher-images.txt` list to create a tarball of all the required images:
        ```(bash)
        ./rancher-save-images.sh --image-list ./rancher-images.txt
        ```
4. Populate the private registry: 
    1. move `rancher-images.tar.gz` to your private registry.
    2. Log into your private registry (optional):
        ```(bash)
        docker login <REGISTRY.YOURDOMAIN.COM:PORT>
        ```
    3. Make `rancher-load-images.sh` executable:
        ```(bash)
        chmod +x rancher-load-images.sh
        ```
    4. Use `rancher-load-images.sh` to extract, tag and push `rancher-images.txt` and `rancher-images.tar.gz` to your private registry:
        ```(bash)
        ./rancher-load-images.sh --image-list ./rancher-images.txt --registry <REGISTRY.YOURDOMAIN.COM:PORT>
        ```

---

## 3. Collect and Publish images to your private registry 

[Collect and Publish images to your private registry Page](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/air-gapped-helm-cli-install/install-kubernetes)

> How to install a dedicated Kubernetes cluster for Rancher Air Gap Install 

1. Prepare Images Directory
    - Obtain the images tar file for your architecture from the releases page for the K3s version.
    - Place the tar file in the `images` Directory before starting K3s on each node:
        ```(bash)
        sudo mkdir -p /var/lib/rancher/k3s/agent/images/
        sudo cp ./k3s-airgap-images-$ARCH.tar /var/lib/rancher/k3s/agent/images/
        ```
2. Create Registry yaml 
    - Only secure registries are supported with K3s (SSL with custom CA): [Private Registry Configurations K3s](https://docs.k3s.io/installation/private-registry)
    - at `/etc/rancher/k3s/registries.yaml`
        ```(yaml)
        ---
        mirrors:
        customreg:
            endpoint:
            - "https://ip-to-server:5000"
        configs:
        customreg:
            auth:
            username: xxxxxx # this is the registry username
            password: xxxxxx # this is the registry password
            tls:
            cert_file: <path to the cert file used in the registry>
            key_file:  <path to the key file used in the registry>
            ca_file: <path to the ca file used in the registry>
        ```
3. Install K3s:
    - Obtain the K3s binary from [K3s Releases Page](https://github.com/k3s-io/k3s/releases) 
    - Place the binary in `/usr/local/bin` on each node.
    - Obtain the K3S Install script at: [K3s Install Script Raw](https://get.k3s.io)
    - Place the install script anywhere and name it `install.sh`
    - Install K3s on each server:
        ```(bash)
        INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=<VERSION> ./install.sh
        ```
    - Install k3s on each agent: 
        ```(bash)
        INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=<VERSION> K3S_URL=https://<SERVER>:6443 K3S_TOKEN=<TOKEN> ./install.sh
        ```
    - Where `<SERVER>` is the IP or valid DNS of the server.
    - Where `<TOKEN>` is the node-token from the server found at: `/var/lib/rancher/k3s/server/node-token`
4. Save and Start Using the **kubeconfig** file
    - Copy the file at: `/etc/rancher/k3s/k3s.yaml` 
    - Paste it at: `~/.kube/config` on local machine 
    - In the **kubeconfig** file, the `server` directive is defined as `localhost`. 
    - Configure the server as the DNS of your load balancer, referring to port `6443`.
    - The Kubernetes API server will be reached at port `6443`.
    - The Rancher server will be reached at ports `80 and 443`.
    - Example `k3s.yaml` file:
        ```(yaml)
        apiVersion: v1
        clusters:
        - cluster:
            certificate-authority-data: [CERTIFICATE-DATA]
            server: [LOAD-BALANCER-DNS]:6443 # Edit this line
        name: default
        contexts:
        - context:
            cluster: default
            user: default
        name: default
        current-context: default
        kind: Config
        preferences: {}
        users:
        - name: default
        user:
            password: [PASSWORD]
            username: admin
        ``` 

---

## 4. Install Rancher

> How to deploy Rancher for your air gapped environment in a high-availability Kubernetes installation.
> And air gapped environment could be where Rancher server will be installed offline, behind a firewall, or behind a proxy. 

- **Privileged Access for Rancher** is required to run containers within containers, install rancher with `--privileged` option.
  
1. Add the Helm Chart Repository:
   - Install helm
   - `helm repo add`:
   ```(bash)
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
    helm repo add rancher-alpha https://releases.rancher.com/server-charts/alpha
    ```
    - Fetch the latest Rancher Chart. This will pull down the chart and save it in the current directory as `.tgz` file:
        ```(bash)
        helm fetch rancher-stable/rancher --version=v2.4.8
        ```
2. SSL Configuration:
    - Add the cert-manager repo:
        ```(bash)
        helm repo add jetstack https://charts.jetstack.io
        helm repo update
        ```
    - Fetch the latest cert-manager chart available from the [Cert-Manager Helm Chart Repo](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
        ```(bash)
        helm fetch jetstack/cert-manager --version v1.12.3
        ```
    - Download the required CRD file for cert-manager:
        ```(bash)
        curl -L -o cert-manager-crd.yaml https://github.com/cert-manager/cert-manager/releases/download/v1.12.3/cert-manager.crds.yaml
        ```
3. Install cert-manager:
    - Install cert-manager with the same options you would use to install the chart. 
    - Set the `image.repository` option to pull the image from your private registry. 
        ```(bash)
        kubectl create namespace cert-manager
        kubectl apply -f cert-manager-crd.yaml
        helm install cert-manager ./cert-manager-v1.12.3.tgz \
            --namespace cert-manager \
            --set image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-controller \
            --set webhook.image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-webhook \
            --set cainjector.image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-cainjector \
            --set startupapicheck.image.repository=<REGISTRY.YOURDOMAIN.COM:PORT>/quay.io/jetstack/cert-manager-ctl
        ```
4. Install Rancher:
    - Create namespace for Rancher:
        ```(bash)
        kubectl create namespace cattle-system
        ```
    - Configure and install Rancher to use the private registry:
        ```(bash)
           helm install rancher ./rancher-<VERSION>.tgz \
            --namespace cattle-system \
            --set hostname=<RANCHER.YOURDOMAIN.COM> \
            --set certmanager.version=<CERTMANAGER_VERSION> \
            --set rancherImage=<REGISTRY.YOURDOMAIN.COM:PORT>/rancher/rancher \
            --set systemDefaultRegistry=<REGISTRY.YOURDOMAIN.COM:PORT> \ # Set a default private registry to be used in Rancher
            --set useBundledSystemChart=true # Use the packaged Rancher system charts
        ```

