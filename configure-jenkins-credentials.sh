#!/bin/bash

# Jenkins AWS Credential Setup Script
# This script helps configure AWS credentials for Jenkins

echo "🔐 Jenkins AWS Credential Configuration Helper"
echo "=============================================="
echo ""

# Check if AWS CLI is configured locally
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✅ AWS CLI is configured locally"
    echo "Current AWS Identity:"
    aws sts get-caller-identity
    echo ""
    
    # Extract credentials if available
    if [ -f "$HOME/.aws/credentials" ]; then
        echo "📋 AWS Credentials found in ~/.aws/credentials"
        echo "You can use these for Jenkins configuration:"
        echo ""
        
        # Show available profiles
        echo "Available AWS profiles:"
        grep '^\[' "$HOME/.aws/credentials" | sed 's/\[//g' | sed 's/\]//g'
        echo ""
        
        # Get default profile credentials
        if grep -q '^\[default\]' "$HOME/.aws/credentials"; then
            echo "Default profile credentials:"
            echo "Access Key ID: $(grep -A 10 '^\[default\]' "$HOME/.aws/credentials" | grep 'aws_access_key_id' | cut -d'=' -f2 | xargs)"
            echo "Secret Access Key: $(grep -A 10 '^\[default\]' "$HOME/.aws/credentials" | grep 'aws_secret_access_key' | cut -d'=' -f2 | xargs | sed 's/./*/g')"
            echo ""
        fi
    fi
else
    echo "❌ AWS CLI is not configured"
    echo "Please configure AWS CLI first:"
    echo "  aws configure"
    echo ""
    exit 1
fi

echo "🎯 Jenkins Credential Configuration Steps:"
echo ""
echo "1. Open Jenkins Dashboard"
echo "2. Navigate to: Manage Jenkins → Credentials → System → Global credentials"
echo "3. Click 'Add Credentials'"
echo "4. Configure as follows:"
echo "   - Kind: Username with password"
echo "   - Scope: Global"
echo "   - Username: [Your AWS Access Key ID]"
echo "   - Password: [Your AWS Secret Access Key]"
echo "   - ID: aws-cli"
echo "   - Description: AWS CLI Credentials for Cassandra Pipeline"
echo "5. Click 'OK' to save"
echo ""

echo "🔑 SSH Key Information:"
echo "SSH Public Key Location: $HOME/.ssh/cassandra-cluster-key.pub"
if [ -f "$HOME/.ssh/cassandra-cluster-key.pub" ]; then
    echo "SSH Public Key Content:"
    echo "----------------------------------------"
    cat "$HOME/.ssh/cassandra-cluster-key.pub"
    echo "----------------------------------------"
else
    echo "⚠️ SSH key not found. Run setup-cassandra-pipeline.sh first"
fi

echo ""
echo "🚀 After Jenkins configuration is complete:"
echo "1. Run the Cassandra pipeline in Jenkins"
echo "2. Use the SSH public key above in the SSH_PUBLIC_KEY parameter"
echo "3. The pipeline should now execute successfully"
echo ""

# Create a Jenkins-specific configuration summary
cat > jenkins-config-summary.txt << EOF
Jenkins Configuration Summary
Generated: $(date)

Required Jenkins Credentials:
- ID: aws-cli
- Type: Username with password
- Username: $(grep -A 10 '^\[default\]' "$HOME/.aws/credentials" 2>/dev/null | grep 'aws_access_key_id' | cut -d'=' -f2 | xargs || echo "Not found")
- Password: [Your AWS Secret Access Key]

SSH Public Key for Pipeline Parameter:
$(cat "$HOME/.ssh/cassandra-cluster-key.pub" 2>/dev/null || echo "SSH key not found - run setup script first")

Pipeline Parameters:
- DEPLOYMENT_ACTION: deploy
- ENVIRONMENT: dev
- CLUSTER_NAME: cassandra-cluster
- NODE_COUNT: 3
- INSTANCE_TYPE: t3.medium
- AWS_REGION: us-east-1
- ASSIGN_ELASTIC_IPS: true
- ENABLE_MONITORING: true
- SSH_PUBLIC_KEY: [Use the SSH public key above]
EOF

echo "📄 Configuration summary saved to: jenkins-config-summary.txt"