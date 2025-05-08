#!/bin/bash
set -e

# Parameters
IMAGE_URI=$1
TAG=$2
ENVIRONMENT=$3
PORT=$4
CONTAINER_NAME="static-resume-container"

echo "=== Starting $ENVIRONMENT Deployment ==="

# Pull the Docker image
echo "Pulling image: $IMAGE_URI:$TAG"
sudo docker pull "$IMAGE_URI:$TAG"

# Stop and remove old container if exists
echo "Cleaning up previous container..."
sudo docker stop "$CONTAINER_NAME" || true
sudo docker rm "$CONTAINER_NAME" || true

# Run new container
echo "Starting new container..."
sudo docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$PORT":80 \
  -e NODE_ENV="$ENVIRONMENT" \
  --restart unless-stopped \
  "$IMAGE_URI:$TAG"

echo "=== $ENVIRONMENT Deployment Complete ==="