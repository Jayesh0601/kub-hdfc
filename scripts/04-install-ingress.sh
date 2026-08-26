#!/bin/bash
set -e

echo "======================================"
echo "Install Ingress-NGINX"
echo "RUN THIS ON MASTER"
echo "======================================"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:"
  echo "sudo ./04-install-ingress.sh"
  exit 1
fi

echo "Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/baremetal/deploy.yaml

echo ""
echo "Waiting for ingress controller..."
kubectl wait \
  --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || true

echo ""
echo "Ingress Pods:"
kubectl get pods -n ingress-nginx

echo ""
echo "Ingress Service:"
kubectl get svc -n ingress-nginx

echo ""
echo "IMPORTANT:"
echo "Find the HTTP NodePort from the service output."
echo "Example: 80:30080/TCP"
