#!/bin/bash

# Cassandra Pipeline Setup Script
# This script prepares the Jenkins environment for Cassandra deployment

set -e

echo "🚀 Setting up Cassandra Pipeline Environment"
echo "============================================="

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key pair if it doesn't exist
SSH_KEY_PATH="$HOME/.ssh/cassandra-cluster-key"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "🔑 Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "cassandra-cluster-$(date +%Y%m%d)"
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_KEY_PATH.pub"
    echo "✅ SSH key pair generated: $SSH_KEY_PATH"
else
    echo "✅ SSH key pair already exists: $SSH_KEY_PATH"
fi

# Display public key for reference
echo ""
echo "📋 Your SSH Public Key (copy this to Jenkins parameters if needed):"
echo "-------------------------------------------------------------------"
cat "$SSH_KEY_PATH.pub"
echo "-------------------------------------------------------------------"

# Check AWS CLI configuration
echo ""
echo "☁️ Checking AWS Configuration..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✅ AWS CLI is configured"
    aws sts get-caller-identity
else
    echo "❌ AWS CLI is not configured"
    echo "Please run: aws configure"
    echo "Or set up Jenkins AWS credentials with ID 'aws-cli'"
fi

# Check Terraform installation
echo ""
echo "🏗️ Checking Terraform..."
if command -v terraform >/dev/null 2>&1; then
    echo "✅ Terraform is installed: $(terraform version | head -1)"
else
    echo "❌ Terraform is not installed"
    echo "Please install Terraform: https://terraform.io/downloads"
fi

# Create workspace directory structure
echo ""
echo "📁 Setting up workspace directories..."
mkdir -p ./aws-topology/cassandra-cluster
echo "✅ Workspace directories created"

# Check if git repository exists
echo ""
echo "📦 Checking repository access..."
if git ls-remote https://github.com/MuddyThunder1040/aws-topology.git >/dev/null 2>&1; then
    echo "✅ aws-topology repository is accessible"
else
    echo "⚠️ aws-topology repository may not exist or is not accessible"
    echo "The pipeline will use local configuration"
fi

echo ""
echo "🎉 Setup completed!"
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials in Jenkins (credential ID: 'aws-cli')"
echo "2. Copy the SSH public key above to Jenkins pipeline parameters"
echo "3. Run the Cassandra deployment pipeline"
echo ""

# Create a summary file
cat > cassandra-setup-summary.txt << EOF
Cassandra Pipeline Setup Summary
Generated: $(date)

SSH Key Location: $SSH_KEY_PATH
SSH Public Key: $(cat "$SSH_KEY_PATH.pub")

AWS Configuration: $(aws sts get-caller-identity 2>/dev/null || echo "Not configured")
Terraform Version: $(terraform version 2>/dev/null | head -1 || echo "Not installed")

Required Jenkins Configuration:
1. AWS Credentials (ID: aws-cli, Type: Username with password)
2. SSH Public Key Parameter (copy from above)
EOF

echo "📄 Setup summary saved to: cassandra-setup-summary.txt"