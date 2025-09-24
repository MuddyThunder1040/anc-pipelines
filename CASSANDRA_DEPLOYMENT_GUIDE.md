# Cassandra Cluster Deployment Pipelines

This directory contains multiple deployment pipelines and tools for deploying 3-node Cassandra clusters on AWS.

## 🚀 Available Deployment Options

### 1. **CassandraDeployJenkinsfile** - Full Featured Pipeline
**Best for:** Production deployments with full control and validation

**Features:**
- ✅ Complete deployment workflow with validation
- ✅ Environment-specific configurations (dev/staging/prod)
- ✅ Auto-generated SSH keys and variables
- ✅ Comprehensive pre and post-deployment checks
- ✅ Backup and restore capabilities
- ✅ Scaling operations
- ✅ Detailed reporting and logging

**Parameters:**
- Deployment action (deploy/plan/destroy/validate/scale/backup)
- Environment (dev/staging/prod)
- Cluster configuration (name, nodes, instance type)
- Advanced options (monitoring, IPs, custom variables)

### 2. **CassandraQuickDeployJenkinsfile** - Simplified Pipeline
**Best for:** Development and quick deployments

**Features:**
- ✅ Streamlined deployment process
- ✅ Minimal configuration required
- ✅ Auto-generated SSH keys
- ✅ Basic validation
- ✅ Quick scale operations

**Parameters:**
- Action (deploy/destroy/status/scale)
- Basic cluster settings
- Auto-approve option

### 3. **CassandraDockerDeployJenkinsfile** - Containerized Pipeline
**Best for:** Containerized Jenkins environments

**Features:**
- ✅ Runs in Docker container with Terraform
- ✅ Credential management via Jenkins
- ✅ Clean container environment
- ✅ Automatic dependency installation

**Requirements:**
- Docker-enabled Jenkins agent
- AWS credentials in Jenkins
- SSH key credentials in Jenkins

### 4. **deploy-cassandra.sh** - Standalone Script
**Best for:** Command-line deployments and automation

**Features:**
- ✅ Complete CLI interface
- ✅ Configuration file support
- ✅ Dry-run capability
- ✅ Comprehensive logging
- ✅ Multiple deployment actions

## 📋 Quick Start Guide

### Option 1: Jenkins Pipeline (Recommended)

1. **Create Jenkins Pipeline Job:**
   ```bash
   # In Jenkins, create new Pipeline job
   # Point to one of the Jenkinsfiles above
   ```

2. **Configure Parameters:**
   - Select deployment action
   - Set cluster name and environment
   - Choose instance type and node count
   - Configure SSH access

3. **Run Pipeline:**
   - Review parameters
   - Execute deployment
   - Monitor progress in Jenkins console

### Option 2: Standalone Script

1. **Setup Configuration:**
   ```bash
   cp deploy-config.env.example deploy-config.env
   vim deploy-config.env  # Edit your settings
   ```

2. **Deploy Cluster:**
   ```bash
   # Deploy 3-node development cluster
   ./deploy-cassandra.sh deploy --name my-cassandra --env dev --size 3
   
   # Scale to 5 nodes
   ./deploy-cassandra.sh scale --name my-cassandra --env dev --size 5
   
   # Check status
   ./deploy-cassandra.sh status --name my-cassandra
   
   # Destroy cluster
   ./deploy-cassandra.sh destroy --name my-cassandra --env dev
   ```

## 🔧 Configuration Options

### Environment-Specific Defaults

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| **VPC CIDR** | 10.30.0.0/16 | 10.20.0.0/16 | 10.10.0.0/16 |
| **Data Volume** | 100GB | 200GB | 500GB |
| **SSH Access** | Open (0.0.0.0/0) | Open (0.0.0.0/0) | Restricted (10.0.0.0/8) |
| **Encryption in Transit** | Disabled | Disabled | Enabled |
| **Log Retention** | 14 days | 14 days | 30 days |
| **Backup Retention** | 7 days | 7 days | 30 days |

### Instance Type Recommendations

| Use Case | Instance Type | Memory | vCPUs | Monthly Cost* |
|----------|--------------|---------|-------|---------------|
| **Development** | t3.medium | 4 GB | 2 | ~$30 |
| **Testing** | m5.large | 8 GB | 2 | ~$70 |
| **Small Production** | m5.xlarge | 16 GB | 4 | ~$140 |
| **Large Production** | r5.xlarge | 32 GB | 4 | ~$180 |

*Prices are estimates for US East region

## 🛠️ Pipeline Comparison

| Feature | Full Pipeline | Quick Pipeline | Docker Pipeline | CLI Script |
|---------|--------------|----------------|-----------------|------------|
| **Environment Support** | ✅ Dev/Staging/Prod | ✅ Basic | ✅ All | ✅ All |
| **Validation** | ✅ Comprehensive | ✅ Basic | ✅ Basic | ✅ Comprehensive |
| **Backup/Restore** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Scaling** | ✅ Advanced | ✅ Basic | ❌ Manual | ✅ Yes |
| **Reporting** | ✅ Detailed | ✅ Basic | ✅ Basic | ✅ Detailed |
| **Setup Complexity** | 🟡 Medium | 🟢 Easy | 🟡 Medium | 🟢 Easy |
| **Container Support** | ❌ No | ❌ No | ✅ Yes | ❌ No |

## 📊 Deployment Workflow

### Standard Deployment Process

1. **Pre-Deployment:**
   - Validate parameters and prerequisites
   - Generate SSH keys (if needed)
   - Create environment-specific configuration
   - Check AWS credentials and permissions

2. **Infrastructure Deployment:**
   - Initialize Terraform
   - Create execution plan
   - Apply infrastructure changes
   - Monitor deployment progress

3. **Post-Deployment:**
   - Wait for Cassandra initialization
   - Validate cluster health
   - Generate connection information
   - Create deployment report

4. **Operational Tasks:**
   - Monitor cluster status
   - Perform scaling operations
   - Create backups
   - Handle maintenance

## 🔍 Monitoring and Validation

### Health Checks Performed

1. **Infrastructure Level:**
   - EC2 instances running
   - Security groups configured
   - EBS volumes attached
   - Elastic IPs assigned

2. **Network Level:**
   - SSH connectivity
   - Inter-node communication
   - Port accessibility

3. **Application Level:**
   - Cassandra service running
   - CQL connectivity
   - Cluster status
   - Node joining

### Monitoring Integration

- **CloudWatch Logs:** System, GC, and application logs
- **CloudWatch Metrics:** CPU, memory, disk, network
- **JMX Monitoring:** Cassandra-specific metrics on port 7199
- **Health Endpoints:** Automated health checking

## 🚨 Troubleshooting

### Common Issues and Solutions

1. **SSH Connection Failed:**
   ```bash
   # Check security groups allow SSH from your IP
   # Verify SSH key permissions: chmod 600 ~/.ssh/cassandra-cluster-key
   ```

2. **Terraform Apply Failed:**
   ```bash
   # Check AWS credentials and permissions
   # Verify region availability and quotas
   # Review Terraform logs for specific errors
   ```

3. **Cassandra Won't Start:**
   ```bash
   # Check instance resources (memory, disk)
   # Review Cassandra logs: /var/log/cassandra/system.log
   # Verify Java installation and heap settings
   ```

4. **Cluster Nodes Not Joining:**
   ```bash
   # Check security groups allow inter-node communication
   # Verify seed node configuration
   # Check network connectivity between nodes
   ```

### Getting Help

1. **Check Pipeline Logs:** Review Jenkins console output
2. **Validation Script:** Run `validate-cluster.sh` for detailed diagnostics
3. **CloudWatch Logs:** Check centralized logging for error details
4. **AWS Console:** Verify resource creation and configuration

## 💰 Cost Management

### Cost Optimization Tips

1. **Right-size Instances:** Start small and scale up as needed
2. **Use Reserved Instances:** Save up to 75% for production workloads
3. **Optimize Storage:** Use appropriate volume types and sizes
4. **Monitor Usage:** Set up billing alerts and cost dashboards

### Estimated Monthly Costs

**3-Node Development Cluster:**
- Instance Type: t3.medium
- Storage: 100GB per node
- **Total: ~$120/month**

**3-Node Production Cluster:**
- Instance Type: m5.large
- Storage: 200GB per node
- **Total: ~$280/month**

## 🔄 Maintenance Operations

### Regular Maintenance Tasks

1. **Weekly:**
   - Monitor cluster health
   - Check CloudWatch metrics
   - Review log files

2. **Monthly:**
   - Create backups
   - Review cost optimization
   - Update security patches

3. **Quarterly:**
   - Performance tuning
   - Capacity planning
   - Disaster recovery testing

### Scaling Operations

```bash
# Scale up (add nodes)
./deploy-cassandra.sh scale --name prod-cassandra --size 5

# Scale down (manual process required)
# 1. Decommission nodes with nodetool
# 2. Update node_count in configuration
# 3. Run terraform apply
```

## 📚 Additional Resources

- [Cassandra Documentation](https://cassandra.apache.org/doc/)
- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)

---

**🎯 Choose the deployment method that best fits your needs and environment!**