# ANC Pipelines - Master Branch

Advanced Jenkins CI/CD pipeline collection for automated deployment and management of applications and database infrastructure on AWS.

## 🚀 Repository Structure

This repository is organized into **specialized branches**, each containing focused pipeline collections for specific use cases:

### 🗄️ Database Deploy Branch (`database-deploy`)

**Unified database deployment pipeline supporting both Cassandra and DynamoDB**

```bash
git checkout database-deploy
```

**Contains:**
- `DatabaseDeployJenkinsfile` - Unified pipeline for both database types
- `database-deploy.sh` - Interactive CLI deployment script
- AWS Free Tier optimization ($0.00/month configurations)
- Cost estimation and deployment guidance

**Use Cases:**
- Choose between Apache Cassandra or Amazon DynamoDB
- Free tier deployments for development/learning
- Production-ready database clusters
- Automated backup and scaling operations

---

### 🔧 Cassandra Deploy Branch (`cassandra-deploy`)

**Dedicated Cassandra cluster deployment and management**

```bash
git checkout cassandra-deploy
```

**Contains:**
- `CassandraDeployJenkinsfile` - Complete cluster deployment
- `CassandraQuickDeployJenkinsfile` - Rapid development deployment
- `CassandraRestackJenkinsfile` - Cluster maintenance operations
- `deploy-cassandra.sh` - Direct deployment script

**Use Cases:**
- Multi-node Cassandra clusters
- Auto-scaling groups with load balancing
- Production-ready with monitoring
- Development and testing environments

---

### 🏗️ Cassandra AMI Branch (`cassandra-ami`)

**AMI building and cluster restacking operations**

```bash
git checkout cassandra-ami
```

**Contains:**
- `CassandraAMIBuildJenkinsfile` - Custom AMI creation
- `CassandraAMIRestackJenkinsfile` - Cluster restacking with new AMIs
- `cassandra-ami-restack.sh` - Direct restacking script
- Pre-configured, optimized Cassandra AMIs

**Use Cases:**
- Build custom Cassandra AMIs with optimizations
- Zero-downtime cluster updates
- Standardized configurations across environments
- Security hardening and performance tuning

---

### 🐳 Docker Deploy Branch (`docker-deploy`)

**Container management and Docker-based deployments**

```bash
git checkout docker-deploy
```

**Contains:**
- `DockerManagerJenkinsfile` - Container lifecycle management
- `CassandraDockerDeployJenkinsfile` - Containerized Cassandra
- ECS/EKS integration
- Container orchestration and scaling

**Use Cases:**
- Docker container management
- Containerized Cassandra deployments
- Kubernetes/ECS orchestration
- Container scaling and monitoring

---

### 🌐 Express App Branch (`express-app`)

**Express.js application CI/CD and deployment automation**

```bash
git checkout express-app
```

**Contains:**
- `ExpressAppJenkinsfile` - Complete Node.js CI/CD pipeline
- `JenkinsFile` - Generic application deployment
- `ExpressApp.groovy` - Deployment automation
- `tf-operations.groovy` - Terraform operations

**Use Cases:**
- Express.js application deployment
- Node.js CI/CD with testing
- Application scaling and monitoring
- Database integration (Cassandra/DynamoDB)

---

## 🎯 Quick Start Guide

### For Database Deployment
```bash
# Clone repository
git clone <repository-url>
cd anc-pipelines

# Switch to database-deploy branch
git checkout database-deploy

# Use interactive deployment
./database-deploy.sh

# Or use Jenkins pipeline with DatabaseDeployJenkinsfile
```

### For Application Deployment
```bash
# Switch to express-app branch
git checkout express-app

# Use Jenkins pipeline with ExpressAppJenkinsfile
# Configure your application parameters and deploy
```

### For Container Management
```bash
# Switch to docker-deploy branch
git checkout docker-deploy

# Use DockerManagerJenkinsfile for container operations
# Configure container parameters and deploy
```

## 🔧 Branch Selection Guide

| **Use Case** | **Branch** | **Pipeline** | **Best For** |
|--------------|------------|--------------|--------------|
| **Database Choice** | `database-deploy` | `DatabaseDeployJenkinsfile` | First-time users, cost optimization |
| **Cassandra Focus** | `cassandra-deploy` | `CassandraDeployJenkinsfile` | Dedicated Cassandra deployments |
| **AMI Management** | `cassandra-ami` | `CassandraAMIBuildJenkinsfile` | Custom AMIs, cluster updates |
| **Containerization** | `docker-deploy` | `DockerManagerJenkinsfile` | Container-based deployments |
| **Web Applications** | `express-app` | `ExpressAppJenkinsfile` | Node.js/Express.js apps |

## 🛠️ Features Across All Branches

### 🔐 Security & Compliance
- ✅ AWS credential integration with Jenkins
- ✅ VPC isolation and security groups
- ✅ Encrypted storage and data at rest
- ✅ IAM role-based access control
- ✅ SSL/TLS encryption for data in transit

### 💰 Cost Optimization
- ✅ AWS Free Tier configurations
- ✅ Cost estimation and monitoring
- ✅ Resource optimization guidelines
- ✅ Development-friendly pricing

### 📊 Monitoring & Operations
- ✅ CloudWatch integration
- ✅ Health checks and alerting
- ✅ Performance monitoring
- ✅ Automated backup strategies
- ✅ Disaster recovery planning

### 🚀 Deployment Options
- ✅ Development/staging/production environments
- ✅ Rolling deployments with zero downtime
- ✅ Blue-green deployment strategies
- ✅ Auto-scaling capabilities
- ✅ Load balancing and high availability

## 📋 Prerequisites

### AWS Requirements
- AWS account with appropriate service permissions
- AWS CLI configured or Jenkins AWS credentials
- VPC and networking setup knowledge

### Jenkins Requirements
- Jenkins with Pipeline plugin
- Git access to repository branches
- AWS credentials configured (credential ID: `aws-cli`)
- Terraform 1.0+ available in environment

### Development Tools
- Git for version control and branch management
- Text editor for configuration customization
- Basic understanding of CI/CD concepts

## 🔄 Branch Management

### Switching Between Branches
```bash
# List all available branches
git branch -a

# Switch to specific branch
git checkout <branch-name>

# Create new branch from specific branch
git checkout -b my-feature cassandra-deploy
```

### Keeping Branches Updated
```bash
# Update master branch
git checkout master
git pull origin master

# Update specific branch
git checkout database-deploy
git pull origin database-deploy
```

## 📚 Documentation Per Branch

Each branch contains comprehensive documentation:

- **README.md** - Branch-specific guide and quick start
- **CASSANDRA_DEPLOYMENT_GUIDE.md** - Detailed deployment instructions
- **CREDENTIAL_INTEGRATION_SUMMARY.md** - AWS credential setup guide
- **deploy-config.env.example** - Configuration templates

## 🤝 Contributing

### Adding New Pipelines
1. Choose appropriate branch based on pipeline type
2. Create feature branch from target branch
3. Add pipeline with comprehensive documentation
4. Test pipeline in development environment
5. Submit pull request to target branch

### Branch-Specific Contributions
- **database-deploy**: New database types, cost optimizations
- **cassandra-deploy**: Cassandra-specific features, performance tuning
- **cassandra-ami**: AMI optimizations, security hardening
- **docker-deploy**: Container orchestration, scaling improvements
- **express-app**: Application features, CI/CD enhancements

## 🆘 Support & Troubleshooting

### Getting Help
1. **Check branch-specific README** for detailed instructions
2. **Review deployment guides** for comprehensive setup information
3. **Examine configuration examples** for proper parameter setup
4. **Check credential integration** for AWS authentication issues

### Common Issues
- **Branch confusion**: Always verify current branch with `git branch`
- **Missing files**: Ensure you're on the correct branch for your use case
- **AWS permissions**: Verify credentials and IAM permissions
- **Pipeline failures**: Check branch-specific troubleshooting guides

---

## 🌟 Repository Highlights

- **5 Specialized Branches** for focused development
- **Unified Database Pipeline** supporting Cassandra and DynamoDB
- **AWS Free Tier Optimization** for cost-effective learning
- **Enterprise Security** with comprehensive credential integration
- **Complete CI/CD** from development to production
- **Comprehensive Documentation** for all use cases

**Choose your branch and start deploying! 🚀**
