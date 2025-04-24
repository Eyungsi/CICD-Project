#!/bin/bash
set -ex

DEPLOY_DIR="/var/www/html/prod"

# Detect OS and install Apache accordingly
if command -v apt &>/prod/null; then
  sudo apt update
  sudo apt install -y apache2
  APACHE_SERVICE="apache2"
  CONFIGTEST_CMD="apache2ctl configtest"
elif command -v dnf &>/prod/null; then
  sudo dnf install -y httpd
  APACHE_SERVICE="httpd"
  CONFIGTEST_CMD="apachectl configtest"
elif command -v yum &>/prod/null; then
  sudo yum install -y httpd
  APACHE_SERVICE="httpd"
  CONFIGTEST_CMD="apachectl configtest"
else
  echo "No supported package manager found!"
  exit 1
fi

# Stop existing Apache service
sudo systemctl stop $APACHE_SERVICE || true
sudo fuser -k 80/tcp || true

# Deploy content
sudo rm -rf $DEPLOY_DIR/*
sudo mkdir -p $DEPLOY_DIR
sudo cp -r /tmp/static-resume/* $DEPLOY_DIR/
sudo chown -R apache:apache $DEPLOY_DIR || sudo chown -R www-data:www-data $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Restore SELinux context if enabled
if command -v sestatus &>/prod/null && sudo sestatus | grep -q enabled; then
  sudo restorecon -Rv $DEPLOY_DIR
fi

# Validate Apache config and restart service
$CONFIGTEST_CMD
sudo systemctl start $APACHE_SERVICE

echo "Prod deployment complete"
