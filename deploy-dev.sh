#!/bin/bash
set -ex

DEPLOY_DIR="/var/www/html/dev"

# Install Apache if it's not already installed
if ! command -v apache2 &>/dev/null; then
  sudo apt update
  sudo apt install -y apache2
  sudo systemctl enable apache2
fi

# Stop Apache before deploying
sudo systemctl stop apache2 || true
sudo fuser -k 80/tcp || true

# Clear old content and copy new files
sudo rm -rf $DEPLOY_DIR/*
sudo mkdir -p $DEPLOY_DIR
sudo cp -r /tmp/static-resume/* $DEPLOY_DIR/
sudo chown -R www-data:www-data $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Validate and restart
