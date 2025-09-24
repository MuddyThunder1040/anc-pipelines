# Jenkins Cassandra Pipeline Configuration Guide

## 🚨 Pipeline Failure Analysis

Your pipeline failed due to missing configurations:

1. **SSH Public Key Missing** ❌
2. **AWS Credentials Not Configured** ❌  
3. **Terraform State Directory Missing** ❌

## 🔧 Quick Fix Steps

### Step 1: Configure AWS Credentials in Jenkins

1. **Go to Jenkins Dashboard** → **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

2. **Add New Credential**:
   - **Kind**: `Username with password`
   - **Scope**: `Global`
   - **Username**: Your AWS Access Key ID
   - **Password**: Your AWS Secret Access Key  
   - **ID**: `aws-cli`
   - **Description**: `AWS CLI Credentials for Cassandra Pipeline`

### Step 2: Configure SSH Key Parameter

**Option A: Use Parameter (Recommended)**
1. When running the pipeline, fill in the `SSH_PUBLIC_KEY` parameter with:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyASgldzUoN41i0MOD94RBVI2JmugIc98SitLyVbQ1vs3KMU4syAAfICciq7OcrRE3BKEsNNZhjHP5GdA+1GEBZaEnG/bLzzUNErBR7AiJwhJCirD//v4kiupGBwaO27Fb07UAdkY0EJA8PiyYvu1aV52alrqwR25W6mIPBcf8JXiD7geLwtQuY6mzv89hIsZqxTxvnpOOezYhB7scZgdei/sqblvxXVou1yz3k/Qy9VbZnpsBw312kXChUH7taUEMOK/EYWDwVUNzI5Bj+7DhEwSiFyl7rMj8YsRb8R5kYryMWZ8qTQRCqagJGDeNBL8KLf+cfFH5ofFUNumBbjqjK/053vqLClvEz/ZASqyFUWUdDjjts5ld3TmEn9GV7IHKP+76UaU7zUrlTDLC0mCOFYEZYzdmuya3CCd5r9ZmGywQp6ED65Qfrgr5B7yusTvXTxogBbOV0XGdfjYfV5j8T87IvWAvRDiqXI9fdMToZ2VLxyEbqmWIzEULbZ/tCS07s3rYCpXc21Ktg5bxttWlivqLfbM3VyeVnfb0rMcc+DZGzE3Mbun9G+3psWTTAL9sNenKrkTMFdnxnnpbl8UMFRWhhlvfU0AZnHoxAaMKQaLtauSmnrHHyf9d503MzwC1qvqhi4Th+vqsUBT3Ev4AX5C6JT1BRBDzK9krRgJ8Bw== cassandra-cluster-20250923
```

**Option B: Create SSH Key File in Jenkins Workspace**
1. In Jenkins, go to your job workspace
2. Create directory: `mkdir -p .ssh`
3. Create file: `.ssh/cassandra-cluster-key.pub` with the public key above

### Step 3: Fix Terraform Directory Issue

The pipeline expects the `aws-topology` repository to be available. You have two options:

**Option A: Ensure Repository Access** 
- Make sure the `aws-topology` repository exists and is accessible
- The pipeline will automatically clone it

**Option B: Use Local Configuration**
- The pipeline will create local directories if repository is not accessible

## 🚀 Re-run Pipeline with Fixed Configuration

After completing the above steps, re-run your Jenkins pipeline with these parameters:

```
DEPLOYMENT_ACTION: deploy
ENVIRONMENT: dev
CLUSTER_NAME: cassandra-cluster
NODE_COUNT: 3
INSTANCE_TYPE: t3.medium
AWS_REGION: us-east-1
ASSIGN_ELASTIC_IPS: true
ENABLE_MONITORING: true
SSH_PUBLIC_KEY: [paste the SSH public key from above]
```

## 🔍 Pipeline Configuration Verification

Before running, verify:

- ✅ **AWS Credentials**: Credential ID `aws-cli` exists in Jenkins
- ✅ **SSH Public Key**: Either in parameter or `.ssh/cassandra-cluster-key.pub` file exists
- ✅ **Repository Access**: `aws-topology` repository is accessible or local setup is complete
- ✅ **Jenkins Permissions**: Jenkins can create files and run shell commands

## 🛠️ Advanced Configuration

### For Production Deployments

```
DEPLOYMENT_ACTION: deploy
ENVIRONMENT: prod
CLUSTER_NAME: cassandra-prod-cluster
NODE_COUNT: 5
INSTANCE_TYPE: m5.large
AWS_REGION: us-east-1
ASSIGN_ELASTIC_IPS: true
ENABLE_MONITORING: true
```

### For Free Tier Deployments

```
DEPLOYMENT_ACTION: deploy
ENVIRONMENT: dev
CLUSTER_NAME: cassandra-free-cluster
NODE_COUNT: 3
INSTANCE_TYPE: t3.medium
AWS_REGION: us-east-1
ASSIGN_ELASTIC_IPS: false
ENABLE_MONITORING: true
```

## 📊 Expected Pipeline Flow

After configuration, your pipeline should execute these stages:

1. ✅ **Pre-Deployment Validation** - SSH key and parameters validated
2. ✅ **Environment Setup** - Repository cloned, directories created
3. ✅ **SSH Key Management** - Keys configured for EC2 access
4. ✅ **Generate Terraform Variables** - Configuration files created
5. ✅ **Terraform Initialization** - AWS provider initialized
6. ✅ **Terraform Plan** - Infrastructure plan generated
7. ✅ **Execute Deployment Action** - Resources deployed to AWS
8. ✅ **Post-Deployment Validation** - Cluster health verified
9. ✅ **Generate Deployment Report** - Summary and endpoints provided

## 🆘 Troubleshooting Common Issues

### Issue: "Unable to locate credentials"
**Solution**: Ensure AWS credentials are configured with ID `aws-cli`

### Issue: "SSH public key is required"  
**Solution**: Provide SSH public key in parameter or create `.ssh/cassandra-cluster-key.pub`

### Issue: "No state file was found"
**Solution**: This is expected for first deployment - pipeline will create state

### Issue: "Repository may not exist"
**Solution**: Ensure `aws-topology` repository exists or use local configuration

---

## 📞 Support

If issues persist:
1. Check Jenkins console logs for specific error messages
2. Verify AWS account permissions (EC2, VPC, IAM)  
3. Ensure Terraform is available in Jenkins environment
4. Review the full pipeline configuration in `CassandraDeployJenkinsfile`