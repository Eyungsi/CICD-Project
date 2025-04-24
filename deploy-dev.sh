#!/bin/bash
set -ex
DEPLOY_DIR="/var/www/html/dev"

if ! command -v httpd &>/dev/null; then
  sudo dnf install -y httpd
  sudo systemctl enable httpd
fi

sudo systemctl stop httpd || true
sudo fuser -k 80/tcp || true
sudo rm -rf $DEPLOY_DIR/*
sudo mkdir -p $DEPLOY_DIR
sudo cp -r /tmp/static-resume/* $DEPLOY_DIR/
sudo chown -R apache:apache $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

if command -v sestatus &>/dev/null && sudo sestatus | grep -q enabled; then
  sudo restorecon -Rv $DEPLOY_DIR
fi

sudo apachectl configtest
sudo systemctl start httpd
echo "Dev deployment complete"
