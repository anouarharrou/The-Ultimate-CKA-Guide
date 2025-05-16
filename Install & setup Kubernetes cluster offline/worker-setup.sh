#!/bin/bash
# worker-setup.sh

set -euo pipefail

JOIN_COMMAND_FILE="$1"

if [[ ! -f "$JOIN_COMMAND_FILE" ]]; then
    echo "[ERROR] Join command file not found: $JOIN_COMMAND_FILE"
    exit 1
fi

echo "[INFO] Disabling swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "[INFO] Enabling IP forwarding..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "[INFO] Enabling and starting containerd..."
systemctl enable --now containerd

echo "[INFO] Executing kubeadm join command from file..."
bash "$JOIN_COMMAND_FILE"

echo "[SUCCESS] Worker node successfully joined the Kubernetes cluster."
