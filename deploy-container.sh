#!/bin/bash

set -e

IMAGE_NAME=$1
TAG=$2
ENV=$3
PORT=$4

if [[ -z "$IMAGE_NAME" || -z "$TAG" || -z "$ENV" || -z "$PORT" ]]; then
  echo "Usage: $0 <IMAGE_NAME> <TAG> <ENV> <PORT>"
  exit 1
fi

echo " Checking for Docker..."
if ! command -v docker &> /dev/null; then
  echo " Installing Docker..."
  sudo yum update -y
  sudo yum install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker ec2-user
  newgrp docker
fi

echo " Pulling image: $IMAGE_NAME:$TAG"
docker pull "$IMAGE_NAME:$TAG"

echo "Stopping and removing old container..."
docker stop static-resume || true
docker rm static-resume || true

echo " Running container..."
docker run -d --name static-resume -p "$PORT":8080 \
  -e ENV="$ENV" \
  "$IMAGE_NAME:$TAG"

echo "Deployment to $ENV completed!"
