#!/bin/bash

set -e

IMAGE_NAME=$1
ENV=$2
PORT=$3

if [[ -z "$IMAGE_NAME" || -z "$ENV" || -z "$PORT" ]]; then
  echo "Usage: $0 <IMAGE_NAME> <ENV> <PORT>"
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

echo " Pulling latest image: $IMAGE_NAME"
docker pull "$IMAGE_NAME":latest

echo " Stopping and removing old container..."
docker stop static-resume || true
docker rm static-resume || true

echo " Starting new container on port $PORT..."
docker run -d --name static-resume -p "$PORT":8080 \
  -e ENV="$ENV" \
  "$IMAGE_NAME":latest

echo "Deployment to $ENV completed successfully!"
