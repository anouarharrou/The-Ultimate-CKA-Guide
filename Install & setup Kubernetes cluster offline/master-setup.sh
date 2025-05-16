#!/bin/bash
# master-setup.sh
# Usage: Run ./master-setup.sh <flannel|calico|weave>

set -euo pipefail

# Check if CNI argument is provided
if [[ -z "${1:-}" ]]; then
    echo "[ERROR] No CNI specified. Usage: $0 <flannel|calico|weave>"
    exit 1
fi

CNI="$1"

# Define directories and files
DOWNLOAD_DIR="/tmp/k8s-offline"
CNI_DIR="$DOWNLOAD_DIR/cni-plugins"
IMAGES_FILE="$DOWNLOAD_DIR/k8s-images.tar"
IMAGES_DIR="$DOWNLOAD_DIR/images"
K8S_PACKAGES="$DOWNLOAD_DIR/k8s-packages"

# Pre-flight check for offline resources
echo "[INFO] Running pre-flight check on offline resources..."

# Check for Kubernetes binaries
for binary in containerd kubeadm kubelet kubectl; do
    if [[ ! -f "$K8S_PACKAGES/$binary"* ]]; then
        echo "[ERROR] $binary package is missing in $K8S_PACKAGES"
        exit 1
    fi
done

# Check for images file
if [[ ! -f "$IMAGES_FILE" ]]; then
    echo "[ERROR] k8s-images.tar is missing!"
    exit 1
fi

# Check for images list
if [[ ! -f "$IMAGES_DIR/images-list.txt" || ! -s "$IMAGES_DIR/images-list.txt" ]]; then
    echo "[ERROR] images-list.txt is missing or empty!"
    exit 1
fi

# Check for CNI YAMLs
for cni in kube-flannel.yml calico.yaml weave.yaml; do
    if [[ ! -f "$CNI_DIR/$cni" ]]; then
        echo "[ERROR] $cni is missing in $CNI_DIR"
        exit 1
    fi
done

# Check for Ingress Controller YAML
if [[ ! -f "$DOWNLOAD_DIR/ingress-nginx-controller.yaml" ]]; then
    echo "[ERROR] ingress-nginx-controller.yaml is missing!"
    exit 1
fi

# Check for ingress images list
if [[ ! -f "$IMAGES_DIR/ingress-images-list.txt" || ! -s "$IMAGES_DIR/ingress-images-list.txt" ]]; then
    echo "[ERROR] ingress-images-list.txt is missing or empty!"
    exit 1
fi

echo "[INFO] Pre-flight check passed. Proceeding with Kubernetes master setup."

# Install Kubernetes RPM packages
echo "[INFO] Installing Kubernetes RPM packages locally..."
yum localinstall -y "$K8S_PACKAGES"/*.rpm

# Import pre-pulled Kubernetes container images
echo "[INFO] Importing pre-pulled Kubernetes container images..."
ctr images import "$IMAGES_FILE"

# Disable swap and remove from fstab
echo "[INFO] Disabling swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

# Configure sysctl for Kubernetes networking
echo "[INFO] Configuring sysctl for Kubernetes networking..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Enable and start containerd service
echo "[INFO] Enabling and starting containerd service..."
systemctl enable --now containerd

# Initialize Kubernetes master node
echo "[INFO] Initializing Kubernetes master node..."
kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket /run/containerd/containerd.sock

# Set up kubectl access for the current user
echo "[INFO] Configuring kubectl access for the current user..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Apply CNI Plugin
echo "[INFO] Applying CNI Plugin: $CNI from local files..."
case "$CNI" in
  flannel)
    kubectl apply -f "$CNI_DIR/kube-flannel.yml"
    ;;
  calico)
    kubectl apply -f "$CNI_DIR/calico.yaml"
    ;;
  weave)
    kubectl apply -f "$CNI_DIR/weave.yaml"
    ;;
  *)
    echo "[ERROR] Unsupported CNI plugin. Supported options: flannel, calico, weave."
    exit 2
    ;;
esac

# Deploy NGINX Ingress Controller
echo "[INFO] Deploying NGINX Ingress Controller from local file..."
kubectl apply -f "$DOWNLOAD_DIR/ingress-nginx-controller.yaml"

# Generate and save kubeadm join command
echo "[INFO] Generating kubeadm join command..."
kubeadm token create --print-join-command --ttl 0 > /tmp/join-command.sh
chmod +x /tmp/join-command.sh

echo "[SUCCESS] Kubernetes Master Node setup complete."
echo "[INFO] Join command saved to /tmp/join-command.sh"
