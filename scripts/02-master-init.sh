#!/bin/bash
set -e

echo "======================================"
echo "Kubernetes Master Initialization"
echo "RUN THIS ONLY ON MASTER"
echo "======================================"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:"
  echo "sudo ./02-master-init.sh"
  exit 1
fi

echo ""
echo "Private IP addresses:"
hostname -I

read -rp "Enter the MASTER PRIVATE IP to use for kubeadm: " MASTER_IP

if [ -z "$MASTER_IP" ]; then
  echo "Master IP cannot be empty."
  exit 1
fi

echo ""
echo "Initializing Kubernetes..."
kubeadm init \
  --apiserver-advertise-address="$MASTER_IP" \
  --pod-network-cidr=10.244.0.0/16

echo ""
echo "Configuring kubectl..."
mkdir -p /home/ec2-user/.kube
cp /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

echo ""
echo "Installing Flannel Pod Network..."
sudo -u ec2-user kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo ""
echo "======================================"
echo "MASTER SETUP COMPLETE"
echo "======================================"

echo ""
echo "Check Master:"
echo "kubectl get nodes"

echo ""
echo "IMPORTANT:"
echo "Copy the kubeadm join command shown by kubeadm above."
echo "Run that command on the WORKER."

echo ""
echo "If you lost the join command, run:"
echo "kubeadm token create --print-join-command"
