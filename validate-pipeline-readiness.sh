#!/bin/bash

# Pipeline Readiness Validation Script
# Checks if all requirements are met for successful pipeline execution

echo "🔍 Cassandra Pipeline Readiness Check"
echo "====================================="
echo ""

VALIDATION_PASSED=true

# Check 1: SSH Key
echo "1. 🔑 SSH Key Configuration"
if [ -f "$HOME/.ssh/cassandra-cluster-key.pub" ]; then
    echo "   ✅ SSH public key found: $HOME/.ssh/cassandra-cluster-key.pub"
    echo "   📝 Key fingerprint: $(ssh-keygen -lf "$HOME/.ssh/cassandra-cluster-key.pub" 2>/dev/null || echo "Unable to get fingerprint")"
else
    echo "   ❌ SSH public key NOT found"
    echo "   🔧 Fix: Run ./setup-cassandra-pipeline.sh"
    VALIDATION_PASSED=false
fi
echo ""

# Check 2: AWS Configuration  
echo "2. ☁️ AWS Configuration"
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "   ✅ AWS CLI is configured"
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
    echo "   👤 AWS Account: $AWS_ACCOUNT"
    echo "   🏷️ AWS User/Role: $AWS_USER"
else
    echo "   ❌ AWS CLI is NOT configured"
    echo "   🔧 Fix: Run 'aws configure' or set up Jenkins credentials"
    VALIDATION_PASSED=false
fi
echo ""

# Check 3: Terraform
echo "3. 🏗️ Terraform Installation"
if command -v terraform >/dev/null 2>&1; then
    TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)
    echo "   ✅ Terraform is installed: $TERRAFORM_VERSION"
    
    # Check if version is compatible (1.0+)
    if terraform version | grep -q "v1\." || terraform version | grep -q "v0\.1[5-9]"; then
        echo "   ✅ Terraform version is compatible"
    else
        echo "   ⚠️ Terraform version may be too old (recommended: 1.0+)"
    fi
else
    echo "   ❌ Terraform is NOT installed"
    echo "   🔧 Fix: Install Terraform from https://terraform.io/downloads"
    VALIDATION_PASSED=false
fi
echo ""

# Check 4: Git Repository Access
echo "4. 📦 Repository Access"
if git ls-remote https://github.com/MuddyThunder1040/aws-topology.git >/dev/null 2>&1; then
    echo "   ✅ aws-topology repository is accessible"
else
    echo "   ⚠️ aws-topology repository is not accessible"
    echo "   💡 Pipeline will use local configuration (this is OK)"
fi

if git ls-remote https://github.com/MuddyThunder1040/anc-pipelines.git >/dev/null 2>&1; then
    echo "   ✅ anc-pipelines repository is accessible"
else
    echo "   ❌ anc-pipelines repository is NOT accessible"
    echo "   🔧 Fix: Ensure repository exists and is accessible"
    VALIDATION_PASSED=false
fi
echo ""

# Check 5: Required AWS Permissions (basic check)
echo "5. 🔐 AWS Permissions Check"
echo "   Testing basic AWS permissions..."

# Test EC2 permissions
if aws ec2 describe-regions --region us-east-1 >/dev/null 2>&1; then
    echo "   ✅ EC2 describe permissions working"
else
    echo "   ❌ EC2 permissions may be insufficient"
    VALIDATION_PASSED=false
fi

# Test IAM permissions
if aws iam get-user >/dev/null 2>&1 || aws sts get-caller-identity >/dev/null 2>&1; then
    echo "   ✅ IAM/STS permissions working"
else
    echo "   ❌ IAM/STS permissions may be insufficient"
    VALIDATION_PASSED=false
fi
echo ""

# Check 6: Workspace Directories
echo "6. 📁 Workspace Setup"
if [ -d "./aws-topology" ]; then
    echo "   ✅ aws-topology directory exists"
else
    echo "   ⚠️ aws-topology directory not found (will be created by pipeline)"
fi

if [ -f "./CassandraDeployJenkinsfile" ]; then
    echo "   ✅ CassandraDeployJenkinsfile found"
else
    echo "   ❌ CassandraDeployJenkinsfile NOT found"
    echo "   🔧 Fix: Ensure you're in the correct directory"
    VALIDATION_PASSED=false
fi
echo ""

# Final Assessment
echo "🏁 VALIDATION SUMMARY"
echo "===================="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "🎉 ✅ ALL CHECKS PASSED!"
    echo ""
    echo "Your pipeline is ready to run with these parameters:"
    echo ""
    echo "Jenkins Pipeline Parameters:"
    echo "- DEPLOYMENT_ACTION: deploy"
    echo "- ENVIRONMENT: dev"
    echo "- CLUSTER_NAME: cassandra-cluster"
    echo "- NODE_COUNT: 3"
    echo "- INSTANCE_TYPE: t3.medium"
    echo "- AWS_REGION: us-east-1"
    echo "- ASSIGN_ELASTIC_IPS: true"
    echo "- ENABLE_MONITORING: true"
    echo "- SSH_PUBLIC_KEY: $(cat "$HOME/.ssh/cassandra-cluster-key.pub" 2>/dev/null | cut -d' ' -f1-2)..."
    echo ""
    echo "🚀 You can now run the Jenkins pipeline!"
else
    echo "❌ VALIDATION FAILED"
    echo ""
    echo "Please fix the issues above before running the pipeline."
    echo ""
    echo "Quick fix commands:"
    echo "- SSH Key: ./setup-cassandra-pipeline.sh"
    echo "- AWS Config: aws configure"
    echo "- Terraform: brew install terraform (macOS) or download from terraform.io"
fi
echo ""

# Save validation results
cat > pipeline-validation-results.txt << EOF
Pipeline Validation Results
Generated: $(date)

SSH Key: $([ -f "$HOME/.ssh/cassandra-cluster-key.pub" ] && echo "✅ Found" || echo "❌ Missing")
AWS Config: $(aws sts get-caller-identity >/dev/null 2>&1 && echo "✅ Configured" || echo "❌ Not configured")
Terraform: $(command -v terraform >/dev/null 2>&1 && echo "✅ Installed" || echo "❌ Not installed")
Repository Access: $(git ls-remote https://github.com/MuddyThunder1040/anc-pipelines.git >/dev/null 2>&1 && echo "✅ Accessible" || echo "❌ Not accessible")

Overall Status: $([ "$VALIDATION_PASSED" = true ] && echo "✅ READY" || echo "❌ NEEDS FIXES")

Next Steps:
$([ "$VALIDATION_PASSED" = true ] && echo "Run Jenkins pipeline with provided parameters" || echo "Fix the issues identified above")
EOF

echo "📄 Validation results saved to: pipeline-validation-results.txt"