#!/bin/bash
set -e

echo "======================================"
echo "Build and Push HDFC Website Image"
echo "Run on a machine with Docker"
echo "======================================"

read -rp "Enter Docker Hub username: " DOCKER_USERNAME
read -rp "Enter image tag [1.0]: " IMAGE_TAG

IMAGE_TAG=${IMAGE_TAG:-1.0}

if [ -z "$DOCKER_USERNAME" ]; then
  echo "Docker Hub username cannot be empty."
  exit 1
fi

IMAGE="$DOCKER_USERNAME/hdfc-bank:$IMAGE_TAG"

echo ""
echo "Building:"
echo "$IMAGE"

docker build -f docker/Dockerfile -t "$IMAGE" .

echo ""
echo "Login to Docker Hub if needed:"
docker login

echo ""
echo "Pushing:"
echo "$IMAGE"

docker push "$IMAGE"

echo ""
echo "======================================"
echo "IMAGE PUSH COMPLETE"
echo "======================================"
echo "Image:"
echo "$IMAGE"
echo ""
echo "Now update k8s/deployment.yaml:"
echo "image: $IMAGE"
