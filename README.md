# ANC Pipelines

Advanced Jenkins CI/CD pipeline collection for automated deployment and management of the Express App Server and other applications.

## 🚀 Overview

This repository contains a comprehensive suite of Jenkins pipelines designed for:

- **Application Deployment**: Automated Express.js application deployment
- **Docker Management**: Container lifecycle management and orchestration
- **System Monitoring**: Infrastructure health checks and system information gathering
- **CI/CD Automation**: Complete build, test, and deployment workflows

## 📁 Pipeline Collection

### 1. Express App Pipeline (`ExpressAppJenkinsfile`)

**Purpose**: Complete CI/CD pipeline for the Express.js application

**Features**:
- ✅ Source code checkout from GitHub
- ✅ Node.js environment setup and verification
- ✅ Dependency installation with npm ci
- ✅ Comprehensive testing suite execution
- ✅ Code quality analysis with ESLint
- ✅ Test coverage reporting
- ✅ Docker image building and tagging
- ✅ Docker Hub registry push
- ✅ Container deployment and health checks
- ✅ Rollback capabilities on failure
- ✅ Slack notifications for build status

**Stages**:
1. 🔍 **Checkout** - Source code retrieval
2. 🔧 **Setup Node.js** - Environment preparation
3. 📦 **Install Dependencies** - npm package installation
4. 🧪 **Run Tests** - Jest test suite execution
5. 📊 **Generate Coverage** - Test coverage analysis
6. 🔍 **Code Quality** - ESLint static analysis
7. 🐳 **Build Docker Image** - Container image creation
8. 📤 **Push to Registry** - Docker Hub deployment
9. 🚀 **Deploy Container** - Application deployment
10. ✅ **Health Check** - Deployment verification
11. 📢 **Notify** - Slack notifications

### 2. Simple Express Deployment (`ExpressApp.groovy`)

**Purpose**: Lightweight deployment pipeline for quick deployments

**Features**:
- 🔍 GitHub source checkout
- 🔧 Environment setup verification
- 📦 Dependency installation
- 🚀 Direct application deployment
- 🏥 Health check validation

**Use Case**: Development environments and quick deployments

### 3. Docker Manager Pipeline (`DockerManagerJenkinsfile`)

**Purpose**: Comprehensive Docker container and image management

**Features**:
- 🐳 **Container Operations**: Start, stop, restart, status
- 📊 **Container Monitoring**: Resource usage and health checks
- 🔄 **Image Management**: Pull, build, tag, cleanup
- 🗂️ **Multi-target Support**: All containers, specific apps, or individual containers
- 🛡️ **Safety Features**: Force removal options with confirmations
- 📈 **Logging**: Comprehensive operation logging

**Parameters**:
- `ACTION`: start | stop | restart | status
- `CONTAINER_TARGET`: all | express-app | specific
- `SPECIFIC_CONTAINER`: Custom container name/ID
- `FORCE_REMOVE`: Safe removal options
- `IMAGE_ACTION`: none | pull-latest | rebuild

### 4. System Information Pipeline (`Systeminfo.groovy`)

**Purpose**: Infrastructure monitoring and system health checks

**Features**:
- 💻 **System Metrics**: CPU, memory, disk usage
- 🐳 **Docker Information**: Container status, image inventory
- 🌐 **Network Diagnostics**: Connectivity and port checks
- 📊 **Service Monitoring**: Application health verification
- 📈 **Performance Metrics**: Resource utilization analysis

### 5. Generic Jenkins Pipeline (`JenkinsFile`)

**Purpose**: Template pipeline for general CI/CD workflows

**Features**:
- 🔧 Flexible stage configuration
- 📋 Parameter-driven execution
- 🔄 Reusable pipeline components
- 📊 Standard reporting and notifications

## 🛠️ Setup and Configuration

### Prerequisites

- **Jenkins Server**: Version 2.400+ with required plugins
- **Docker**: Docker Engine and Docker Compose
- **Node.js**: Version 18+ for Express app builds
- **Git**: Source code management
- **Docker Hub Account**: For image registry (optional)

### Required Jenkins Plugins

```bash
# Essential plugins for pipeline execution
- Pipeline: Stage View
- Docker Pipeline
- Docker Commons
- Git
- GitHub
- Slack Notification (optional)
- Blue Ocean (recommended)
- Pipeline: Groovy
- Credentials Binding
```

### Jenkins Configuration

1. **Docker Hub Credentials**
   ```bash
   # Add to Jenkins Credentials
   ID: c71d37ab-7559-4e0e-a3ea-fcf087717f4e
   Type: Username with password
   Username: your-dockerhub-username
   Password: your-dockerhub-token
   ```

2. **GitHub Integration**
   ```bash
   # Configure GitHub webhook for automatic builds
   URL: http://your-jenkins-server/github-webhook/
   Content-Type: application/json
   Events: Push, Pull Request
   ```

3. **Slack Notifications** (Optional)
   ```bash
   # Configure Slack workspace integration
   Workspace: your-slack-workspace
   Token: xoxb-your-slack-bot-token
   Channel: #ci-cd-notifications
   ```

### Environment Variables

Set these variables in Jenkins global configuration:

```bash
NODE_VERSION=18
DOCKER_HUB_REPO=muddythunder/express-app
APP_NAME=express-app
CONTAINER_NAME=express-app-container
```

## 🚀 Usage Examples

### Deploy Express Application

```bash
# Trigger via Jenkins UI or webhook
# Pipeline: ExpressAppJenkinsfile
# Branch: main
# Automatic: Push to main branch
```

### Manage Docker Containers

```bash
# Start all containers
curl -X POST "http://jenkins-server/job/docker-manager/buildWithParameters?ACTION=start&CONTAINER_TARGET=all"

# Stop specific container
curl -X POST "http://jenkins-server/job/docker-manager/buildWithParameters?ACTION=stop&CONTAINER_TARGET=specific&SPECIFIC_CONTAINER=my-app"

# Restart Express app
curl -X POST "http://jenkins-server/job/docker-manager/buildWithParameters?ACTION=restart&CONTAINER_TARGET=express-app"
```

### System Health Check

```bash
# Run system information gathering
curl -X POST "http://jenkins-server/job/system-info/build"
```

## 📊 Pipeline Features

### Advanced Error Handling

- **Retry Logic**: Automatic retry for transient failures
- **Rollback Mechanism**: Automatic rollback on deployment failures
- **Graceful Degradation**: Continue pipeline execution where possible
- **Detailed Logging**: Comprehensive error reporting and diagnostics

### Security Features

- **Credential Management**: Secure handling of sensitive information
- **Image Scanning**: Container vulnerability assessment (when configured)
- **Access Control**: Role-based pipeline execution permissions
- **Audit Logging**: Complete audit trail for all operations

### Performance Optimization

- **Parallel Execution**: Concurrent stage execution where possible
- **Cache Management**: Docker layer caching and npm cache optimization
- **Resource Allocation**: Dynamic resource allocation based on workload
- **Build Optimization**: Incremental builds and dependency caching

## 🔧 Customization

### Adding New Pipelines

1. **Create New Jenkinsfile**
   ```groovy
   pipeline {
       agent any
       
       stages {
           stage('Your Stage') {
               steps {
                   echo 'Your pipeline logic here'
               }
           }
       }
   }
   ```

2. **Configure Jenkins Job**
   - Create new Pipeline job
   - Point to your Jenkinsfile
   - Configure triggers and parameters

### Extending Existing Pipelines

1. **Fork the repository**
2. **Modify the relevant Jenkinsfile**
3. **Test in development environment**
4. **Submit pull request**

### Environment-Specific Configuration

```groovy
// Environment-specific pipeline logic
script {
    if (env.BRANCH_NAME == 'main') {
        // Production deployment logic
    } else if (env.BRANCH_NAME == 'develop') {
        // Development deployment logic
    } else {
        // Feature branch testing logic
    }
}
```

## 📈 Monitoring and Observability

### Pipeline Metrics

- **Build Success Rate**: Track deployment success over time
- **Build Duration**: Monitor pipeline performance
- **Resource Usage**: Container and infrastructure metrics
- **Test Coverage**: Code quality and test effectiveness

### Logging Strategy

- **Structured Logging**: JSON-formatted logs for easy parsing
- **Log Aggregation**: Centralized logging with ELK stack (optional)
- **Retention Policies**: Automated log cleanup and archival
- **Alert Configuration**: Notification rules for critical events

### Health Dashboards

Access pipeline and application health through:
- **Jenkins Blue Ocean**: Visual pipeline monitoring
- **Docker Stats**: Container resource monitoring
- **Application Metrics**: Express app health endpoints
- **Custom Dashboards**: Grafana integration (optional)

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch** (`git checkout -b feature/new-pipeline`)
3. **Test your changes** in development environment
4. **Commit your changes** (`git commit -m 'Add new pipeline feature'`)
5. **Push to branch** (`git push origin feature/new-pipeline`)
6. **Create Pull Request**

### Development Guidelines

- **Pipeline Testing**: Test all pipelines in development environment
- **Documentation**: Update README for new features
- **Backward Compatibility**: Ensure existing pipelines continue to work
- **Security Review**: Review for security implications

## 📋 Troubleshooting

### Common Issues

1. **Docker Permission Errors**
   ```bash
   # Add Jenkins user to docker group
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

2. **Node.js Version Issues**
   ```bash
   # Install Node.js version manager
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 18
   nvm use 18
   ```

3. **Pipeline Timeout Issues**
   ```groovy
   // Increase timeout in pipeline
   timeout(time: 30, unit: 'MINUTES') {
       // Your pipeline steps
   }
   ```

### Debug Mode

Enable debug logging in pipelines:

```groovy
pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }
    // ... rest of pipeline
}
```



## 🔗 Related Projects

- [**Express App Server**](../appserver/) - The application being deployed
- [**AWS Topology**](../aws-topology/) - Infrastructure configurations

---

**🚀 Automating deployment excellence with Jenkins CI/CD**
