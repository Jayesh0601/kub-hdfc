#!/bin/bash
set -e

echo "======================================"
echo "Kubernetes Common Setup"
echo "Run this on BOTH Master and Worker"
echo "======================================"

echo "[1/8] Updating Amazon Linux..."
dnf update -y

echo "[2/8] Installing basic tools..."
dnf install -y curl wget git vim

echo "[3/8] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[4/8] Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

echo "[5/8] Configuring Kubernetes networking..."
cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

echo "[6/8] Installing containerd..."
dnf install -y containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

echo "[7/8] Installing Kubernetes repository..."

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "[8/8] Installing kubeadm, kubelet and kubectl..."
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet

echo ""
echo "======================================"
echo "COMMON SETUP COMPLETE"
echo "======================================"
echo "Hostname:"
hostname
echo ""
echo "Containerd:"
systemctl --no-pager --full status containerd | head -15
echo ""
echo "Versions:"
kubeadm version
kubectl version --client
kubelet --version
echo ""
echo "Now:"
echo "- On MASTER: run scripts/02-master-init.sh"
echo "- On WORKER: wait for the kubeadm join command from Master"
