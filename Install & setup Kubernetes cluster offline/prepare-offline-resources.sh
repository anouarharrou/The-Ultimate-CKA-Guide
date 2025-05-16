#!/bin/bash
# prepare-offline-resources.sh
# Purpose: Fully automate Kubernetes offline resource preparation and transfer.
# Usage: ./prepare-offline-resources.sh <DEST_SERVER_IP> [SSH_USER (default: root)]

set -euo pipefail

# === CONFIGURABLES ===
K8S_VERSION="1.29.0-00"
DOWNLOAD_DIR="/tmp/k8s-offline"
IMAGES_FILE="$DOWNLOAD_DIR/k8s-images.tar"
CNI_DIR="$DOWNLOAD_DIR/cni-plugins"
ARCHIVE_FILE="/tmp/k8s-offline.tar.gz"

# === INPUT CHECK ===
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <destination-server> [ssh-user (default: root)]"
  exit 1
fi

DEST_SERVER="$1"
SSH_USER="${2:-root}"

# === GLOBAL VARS ===
PKG_MANAGER=""

# === FUNCTIONS ===

detect_os() {
  echo "[INFO] Detecting OS package manager..."
  if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
  elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
  else
    echo "[ERROR] No supported package manager (apt/yum) found."
    exit 1
  fi
  echo "[INFO] Using package manager: $PKG_MANAGER"
}

install_packages() {
  echo "[INFO] Installing necessary tools..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt-get update
    sudo apt-get install -y curl gnupg lsb-release sshpass containerd
  else
    sudo yum install -y curl gnupg2 redhat-lsb-core sshpass containerd
  fi
}

setup_kubernetes_repo() {
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    echo "[INFO] Setting up Kubernetes apt repository..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
      sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

    sudo apt-get update
  else
    echo "[INFO] Setting up Kubernetes yum repository..."
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    sudo yum clean all
  fi
}

download_k8s_packages() {
  echo "[INFO] Downloading Kubernetes binaries..."
  mkdir -p "$DOWNLOAD_DIR/k8s-packages"

  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt-get install -y --download-only --reinstall -o Dir::Cache::Archives="$DOWNLOAD_DIR/k8s-packages" \
      kubelet="$K8S_VERSION" kubeadm="$K8S_VERSION" kubectl="$K8S_VERSION"
  else
    sudo yum install -y --downloadonly --downloaddir="$DOWNLOAD_DIR/k8s-packages" \
      kubelet-"$K8S_VERSION" kubeadm-"$K8S_VERSION" kubectl-"$K8S_VERSION"
  fi
}

pull_images_parallel() {
  echo "[INFO] Pulling Kubernetes images in parallel..."
  mkdir -p "$DOWNLOAD_DIR/images"
  kubeadm config images list > "$DOWNLOAD_DIR/images/images-list.txt"

  cat "$DOWNLOAD_DIR/images/images-list.txt" | \
    xargs -n1 -P8 -I {} bash -c 'echo "[PULL] {}"; sudo ctr images pull "{}"'
}

download_cni_plugins() {
  echo "[INFO] Downloading CNI plugins..."
  mkdir -p "$CNI_DIR"
  curl -L -o "$CNI_DIR/kube-flannel.yml" https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  curl -L -o "$CNI_DIR/calico.yaml" https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
  curl -L -o "$CNI_DIR/weave.yaml" "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version --client --short | awk '{print $3}')"
}

download_ingress_controller() {
  echo "[INFO] Downloading NGINX Ingress Controller..."
  curl -L -o "$DOWNLOAD_DIR/ingress-nginx-controller.yaml" \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

  echo "[INFO] Extracting ingress images and pulling them..."
  grep 'image:' "$DOWNLOAD_DIR/ingress-nginx-controller.yaml" | awk '{print $2}' | sort -u > "$DOWNLOAD_DIR/images/ingress-images-list.txt"

  cat "$DOWNLOAD_DIR/images/ingress-images-list.txt" | \
    xargs -n1 -P8 -I {} bash -c 'echo "[PULL] {}"; sudo ctr images pull "{}"'
}

export_images() {
  echo "[INFO] Exporting images to $IMAGES_FILE..."
  sudo ctr images export "$IMAGES_FILE" $(cat "$DOWNLOAD_DIR/images/images-list.txt" "$DOWNLOAD_DIR/images/ingress-images-list.txt")
}

archive_resources() {
  echo "[INFO] Archiving resources into $ARCHIVE_FILE..."
  cd /tmp
  tar czf "$(basename "$ARCHIVE_FILE")" "$(basename "$DOWNLOAD_DIR")"
}

transfer_and_extract() {
  echo "[INFO] Transferring archive to $SSH_USER@$DEST_SERVER..."
  scp "$ARCHIVE_FILE" "$SSH_USER@$DEST_SERVER:/tmp/"

  echo "[INFO] Extracting archive remotely..."
  ssh "$SSH_USER@$DEST_SERVER" "cd /tmp && tar xzf $(basename "$ARCHIVE_FILE") && rm -f $(basename "$ARCHIVE_FILE")"

  echo "[SUCCESS] Offline resources are now ready at /tmp/k8s-offline on $DEST_SERVER"
}

# === MAIN FLOW ===
detect_os
install_packages
setup_kubernetes_repo
download_k8s_packages
pull_images_parallel
download_cni_plugins
download_ingress_controller
export_images
archive_resources
transfer_and_extract
