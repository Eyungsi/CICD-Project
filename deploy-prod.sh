#!/bin/bash
set -ex

DEPLOY_DIR="/var/www/html/prod"

# Install Apache if missing
if ! command -v apache2 &>/dev/null; then
  sudo apt update
  sudo apt install -y apache2
  sudo systemctl enable apache2
fi

# Stop Apache before deployment
sudo systemctl stop apache2 || true
sudo fuser -k 80/tcp || true

# Deploy static site
sudo rm -rf $DEPLOY_DIR/*
sudo mkdir -p $DEPLOY_DIR
sudo cp -r /tmp/static-resume/* $DEPLOY_DIR/
sudo chown -R www-data:www-data $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Restart Apache
sudo apache2ctl configtest
sudo systemctl start apache2

# Optional: Verify
curl -I http://localhost/prod || true
echo "Production deployment complete"
