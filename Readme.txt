Resume Template

yum install unzip wget httpd -y
git clone https://github.com/utrains/static-resume.git
rm -rf /var/www/html/*
cp -r static-resume/* /var/www/html/
systemctl start httpd
systemctl enable httpd
.......................................................................................................................................................
Static Resume Deployment to AWS EC2 using GitHub Actions

This README describes the GitHub Actions workflow used to build and deploy a static resume website to AWS EC2 instances for both development and production environments. The CI/CD pipeline automates the build and deployment steps, ensuring consistent delivery across environments.

Workflow Overview

This GitHub Actions workflow is triggered:

On every push to the main branch

Or manually via the GitHub Actions UI (workflow_dispatch)

It consists of three jobs:

build: Prepares the static files

deploy-dev: Deploys to the development EC2 instance

deploy-prod: Deploys to the production EC2 instance, only after successful dev deployment

Environments and Secrets

The workflow requires the following secrets to be configured in your GitHub repository:

AWS_REGION: AWS region (e.g., us-east-1)

DEV_SERVER_IP: Public IP address of the development EC2 instance

PROD_SERVER_IP: Public IP address of the production EC2 instance

SSH_PRIVATE_KEY: SSH private key for accessing EC2 instances

Complete GitHub Actions Workflow with Explanations

# Define the name of the workflow and trigger conditions
name: Deploy Static Resume to AWS EC2

on:
  push:
    branches: ["main"]           # Trigger on push to main
  workflow_dispatch:             # Allow manual trigger

# Set environment-wide variables
env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  APP_NAME: "static-resume"
  DEV_SERVER: ${{ secrets.DEV_SERVER_IP }}
  PROD_SERVER: ${{ secrets.PROD_SERVER_IP }}

jobs:
  # First job to prepare the static files
  build:
    name: Prepare Static Site
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4  # Pull the latest code from GitHub

      - name: Upload HTML files
        uses: actions/upload-artifact@v4  # Upload files as artifact
        with:
          name: static-resume-build
          path: ./  # or ./build if files live in a subfolder

  # Deploy the site to the development environment
  deploy-dev:
    name: Deploy to Development EC2
    needs: build
    runs-on: ubuntu-latest
    environment: development
    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: static-resume-build
          path: build/

      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.7.0  # Add SSH private key to agent
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Deploy to Dev EC2
        run: |
          # Use rsync to copy files to the development EC2 instance
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" build/ ec2-user@${{ env.DEV_SERVER }}:/tmp/static-resume/

          # SSH into the EC2 instance to configure Apache and deploy files
          ssh -o StrictHostKeyChecking=no ec2-user@${{ env.DEV_SERVER }} << 'EOF'
            set -ex
            DEPLOY_DIR="/var/www/html/dev"

            # Install Apache if not installed
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

            # Restore SELinux context if required
            if command -v sestatus &>/dev/null && sudo sestatus | grep -q enabled; then
              sudo restorecon -Rv $DEPLOY_DIR
            fi

            sudo apachectl configtest
            sudo systemctl start httpd
            echo "Dev deployment complete"
          EOF

  # Deploy the site to the production environment
  deploy-prod:
    name: Deploy to Production EC2
    needs: deploy-dev  # Only run after successful dev deploy
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: static-resume-build
          path: build/

      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.7.0  # Set up SSH
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Deploy to Prod EC2
        run: |
          # Copy files to production EC2 server
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" build/ ec2-user@${{ env.PROD_SERVER }}:/tmp/static-resume/

          # SSH into production EC2 and deploy the files
          ssh -o StrictHostKeyChecking=no ec2-user@${{ env.PROD_SERVER }} << 'EOF'
            set -ex
            DEPLOY_DIR="/var/www/html/prod"

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
            curl -I http://localhost/prod || true
            echo "Production deployment complete"
          EOF

          