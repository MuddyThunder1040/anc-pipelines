#!/bin/bash

# Database Deployment CLI Script
# Helps users choose between Cassandra and DynamoDB deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}🗄️  Database Deployment Helper${NC}"
echo -e "${CYAN}====================================${NC}"
echo

# Function to display help
show_help() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 [options]"
    echo
    echo -e "${BLUE}Options:${NC}"
    echo "  -d, --database TYPE     Database type (cassandra|dynamodb)"
    echo "  -m, --mode MODE         Deployment mode (production|free-tier)"
    echo "  -e, --environment ENV   Environment (dev|staging|prod)"
    echo "  -r, --region REGION     AWS region (default: us-east-1)"
    echo "  -c, --cluster NAME      Cluster name"
    echo "  -h, --help             Show this help message"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 --database cassandra --mode free-tier --environment dev"
    echo "  $0 --database dynamodb --mode production --environment prod"
    echo "  $0  # Interactive mode"
}

# Function to validate database type
validate_database() {
    local db="$1"
    if [[ "$db" != "cassandra" && "$db" != "dynamodb" ]]; then
        echo -e "${RED}❌ Invalid database type: $db${NC}"
        echo -e "${YELLOW}Valid options: cassandra, dynamodb${NC}"
        exit 1
    fi
}

# Function to validate deployment mode
validate_mode() {
    local mode="$1"
    if [[ "$mode" != "production" && "$mode" != "free-tier" ]]; then
        echo -e "${RED}❌ Invalid deployment mode: $mode${NC}"
        echo -e "${YELLOW}Valid options: production, free-tier${NC}"
        exit 1
    fi
}

# Function to validate environment
validate_environment() {
    local env="$1"
    if [[ "$env" != "dev" && "$env" != "staging" && "$env" != "prod" ]]; then
        echo -e "${RED}❌ Invalid environment: $env${NC}"
        echo -e "${YELLOW}Valid options: dev, staging, prod${NC}"
        exit 1
    fi
}

# Function for interactive database selection
select_database() {
    echo -e "${PURPLE}📊 Select Database Type:${NC}"
    echo
    echo "1) Apache Cassandra"
    echo "   - Distributed NoSQL database"
    echo "   - High availability and fault tolerance"
    echo "   - Excellent for time-series and IoT data"
    echo "   - Requires EC2 instances (infrastructure management)"
    echo
    echo "2) Amazon DynamoDB"
    echo "   - Fully managed NoSQL database"
    echo "   - Serverless and auto-scaling"
    echo "   - Pay-per-request or provisioned capacity"
    echo "   - No infrastructure management required"
    echo
    
    while true; do
        read -p "Choose database (1-2): " choice
        case $choice in
            1) echo "cassandra"; break;;
            2) echo "dynamodb"; break;;
            *) echo -e "${RED}Please enter 1 or 2${NC}";;
        esac
    done
}

# Function for interactive mode selection
select_mode() {
    echo -e "${PURPLE}💰 Select Deployment Mode:${NC}"
    echo
    echo "1) Free Tier"
    echo "   - Optimized for AWS Free Tier (new accounts)"
    echo "   - Minimal resources and costs"
    echo "   - Perfect for learning and development"
    echo "   - Limited performance and features"
    echo
    echo "2) Production"
    echo "   - Full-featured production deployment"
    echo "   - Optimized for performance and availability"
    echo "   - Higher costs but enterprise-ready"
    echo "   - All monitoring and security features enabled"
    echo
    
    while true; do
        read -p "Choose mode (1-2): " choice
        case $choice in
            1) echo "free-tier"; break;;
            2) echo "production"; break;;
            *) echo -e "${RED}Please enter 1 or 2${NC}";;
        esac
    done
}

# Function for interactive environment selection
select_environment() {
    echo -e "${PURPLE}🌍 Select Environment:${NC}"
    echo
    echo "1) Development (dev)"
    echo "2) Staging (staging)"
    echo "3) Production (prod)"
    echo
    
    while true; do
        read -p "Choose environment (1-3): " choice
        case $choice in
            1) echo "dev"; break;;
            2) echo "staging"; break;;
            3) echo "prod"; break;;
            *) echo -e "${RED}Please enter 1, 2, or 3${NC}";;
        esac
    done
}

# Function to display cost estimation
show_cost_estimation() {
    local database="$1"
    local mode="$2"
    
    echo -e "${CYAN}💰 Cost Estimation:${NC}"
    echo "==================="
    
    if [[ "$mode" == "free-tier" ]]; then
        echo -e "${GREEN}✅ Free Tier Mode Selected${NC}"
        echo
        if [[ "$database" == "cassandra" ]]; then
            echo "Cassandra Free Tier:"
            echo "  • 1x t2.micro instance: $0.00/month (750 hours free)"
            echo "  • 28 GB EBS storage: $0.00/month (30 GB free)"
            echo "  • No load balancer: $0.00/month"
            echo "  • Basic monitoring: $0.00/month"
            echo -e "${GREEN}  Total: $0.00/month (within free tier limits)${NC}"
        else
            echo "DynamoDB Free Tier:"
            echo "  • 25 GB storage: $0.00/month"
            echo "  • 25 RCU + 25 WCU: $0.00/month"
            echo "  • Pay-per-request pricing: varies by usage"
            echo -e "${GREEN}  Total: $0.00/month base cost (data access charges may apply)${NC}"
        fi
        echo
        echo -e "${YELLOW}⚠️  Free tier benefits last 12 months for new AWS accounts${NC}"
    else
        echo -e "${YELLOW}⚠️  Production Mode - Costs Vary${NC}"
        echo
        if [[ "$database" == "cassandra" ]]; then
            echo "Cassandra Production (estimated):"
            echo "  • 3x m5.large instances: ~$200-300/month"
            echo "  • EBS storage (300GB): ~$30/month"
            echo "  • Load balancer: ~$20/month"
            echo "  • Monitoring & backups: ~$10/month"
            echo -e "${YELLOW}  Estimated total: $260-360/month${NC}"
        else
            echo "DynamoDB Production (estimated):"
            echo "  • Provisioned capacity: $50-500+/month"
            echo "  • Pay-per-request: $0.25/million reads, $1.25/million writes"
            echo "  • Storage: $0.25/GB/month"
            echo -e "${YELLOW}  Costs depend heavily on usage patterns${NC}"
        fi
        echo
        echo "💡 Use AWS Cost Calculator for precise estimates"
    fi
    echo
}

# Function to check prerequisites
check_prerequisites() {
    local database="$1"
    
    echo -e "${CYAN}🔍 Checking Prerequisites:${NC}"
    echo "=========================="
    
    # Check AWS CLI
    if command -v aws &> /dev/null; then
        echo -e "${GREEN}✅ AWS CLI installed${NC}"
        
        # Check AWS credentials
        if aws sts get-caller-identity &> /dev/null; then
            echo -e "${GREEN}✅ AWS credentials configured${NC}"
        else
            echo -e "${RED}❌ AWS credentials not configured${NC}"
            echo "Run: aws configure"
            exit 1
        fi
    else
        echo -e "${RED}❌ AWS CLI not found${NC}"
        echo "Install: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        echo -e "${GREEN}✅ Terraform installed${NC}"
    else
        echo -e "${RED}❌ Terraform not found${NC}"
        echo "Install: https://terraform.io/downloads.html"
        exit 1
    fi
    
    # Check workspace directories
    local workspace_dir
    if [[ "$database" == "cassandra" ]]; then
        workspace_dir="$PROJECT_ROOT/aws-topology/cassandra-cluster"
    else
        workspace_dir="$PROJECT_ROOT/aws-topology/dynamodb-cluster"
    fi
    
    if [[ -d "$workspace_dir" ]]; then
        echo -e "${GREEN}✅ Workspace directory found: $workspace_dir${NC}"
    else
        echo -e "${RED}❌ Workspace directory not found: $workspace_dir${NC}"
        exit 1
    fi
    
    echo
}

# Function to generate deployment configuration
generate_config() {
    local database="$1"
    local mode="$2"
    local environment="$3"
    local region="$4"
    local cluster_name="$5"
    
    local workspace_dir
    if [[ "$database" == "cassandra" ]]; then
        workspace_dir="$PROJECT_ROOT/aws-topology/cassandra-cluster"
    else
        workspace_dir="$PROJECT_ROOT/aws-topology/dynamodb-cluster"
    fi
    
    echo -e "${CYAN}📝 Generating Configuration:${NC}"
    echo "============================="
    
    cd "$workspace_dir"
    
    # Copy example to actual tfvars
    if [[ -f "terraform.tfvars.example" ]]; then
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${GREEN}✅ Copied terraform.tfvars.example to terraform.tfvars${NC}"
    else
        echo -e "${YELLOW}⚠️  terraform.tfvars.example not found, creating basic config${NC}"
        touch terraform.tfvars
    fi
    
    # Update basic configuration
    cat >> terraform.tfvars << EOF

# Generated by database-deploy.sh
aws_region = "$region"
environment = "$environment"
cluster_name = "$cluster_name"
EOF
    
    if [[ "$database" == "cassandra" ]]; then
        if [[ "$mode" == "free-tier" ]]; then
            cat >> terraform.tfvars << EOF

# Free Tier Optimizations for Cassandra
instance_type = "t2.micro"
asg_desired_capacity = 1
asg_min_size = 1
asg_max_size = 2
node_count = 1
root_volume_size = 8
data_volume_size = 20
data_volume_iops = 0
data_volume_throughput = 0
create_load_balancer = false
enable_monitoring = false
enable_encryption_at_rest = false
assign_elastic_ips = false
cassandra_heap_size = "512M"
EOF
        fi
    else
        if [[ "$mode" == "free-tier" ]]; then
            cat >> terraform.tfvars << EOF

# Free Tier Optimizations for DynamoDB
billing_mode = "PROVISIONED"
read_capacity = 5
write_capacity = 5
free_tier_mode = true
enable_encryption = false
enable_point_in_time_recovery = false
enable_deletion_protection = false
create_sns_topic = false
enable_monitoring = false
EOF
        fi
    fi
    
    echo -e "${GREEN}✅ Configuration generated in: $workspace_dir/terraform.tfvars${NC}"
    echo
    echo -e "${YELLOW}📝 Edit terraform.tfvars to customize your deployment${NC}"
    echo
}

# Function to run deployment
run_deployment() {
    local database="$1"
    local workspace_dir
    
    if [[ "$database" == "cassandra" ]]; then
        workspace_dir="$PROJECT_ROOT/aws-topology/cassandra-cluster"
    else
        workspace_dir="$PROJECT_ROOT/aws-topology/dynamodb-cluster"
    fi
    
    cd "$workspace_dir"
    
    echo -e "${CYAN}🚀 Starting Deployment:${NC}"
    echo "======================"
    echo
    
    # Initialize Terraform
    echo -e "${BLUE}Initializing Terraform...${NC}"
    terraform init
    echo
    
    # Validate configuration
    echo -e "${BLUE}Validating configuration...${NC}"
    terraform validate
    echo
    
    # Create plan
    echo -e "${BLUE}Creating deployment plan...${NC}"
    terraform plan -out=tfplan
    echo
    
    # Ask for confirmation
    echo -e "${YELLOW}⚠️  Review the plan above carefully${NC}"
    read -p "Do you want to apply this plan? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        echo
        echo -e "${GREEN}🚀 Applying deployment...${NC}"
        terraform apply tfplan
        echo
        echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
        echo
        echo -e "${CYAN}🔗 Connection Information:${NC}"
        terraform output
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
        rm -f tfplan
    fi
}

# Parse command line arguments
DATABASE=""
MODE=""
ENVIRONMENT=""
REGION="us-east-1"
CLUSTER_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--database)
            DATABASE="$2"
            validate_database "$DATABASE"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            validate_mode "$MODE"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            validate_environment "$ENVIRONMENT"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Interactive mode if parameters not provided
if [[ -z "$DATABASE" ]]; then
    DATABASE=$(select_database)
fi

if [[ -z "$MODE" ]]; then
    MODE=$(select_mode)
fi

if [[ -z "$ENVIRONMENT" ]]; then
    ENVIRONMENT=$(select_environment)
fi

if [[ -z "$CLUSTER_NAME" ]]; then
    read -p "Enter cluster name (default: ${DATABASE}-cluster): " CLUSTER_NAME
    CLUSTER_NAME=${CLUSTER_NAME:-"${DATABASE}-cluster"}
fi

echo
echo -e "${CYAN}📋 Deployment Summary:${NC}"
echo "====================="
echo -e "Database: ${GREEN}$DATABASE${NC}"
echo -e "Mode: ${GREEN}$MODE${NC}"
echo -e "Environment: ${GREEN}$ENVIRONMENT${NC}"
echo -e "Region: ${GREEN}$REGION${NC}"
echo -e "Cluster Name: ${GREEN}$CLUSTER_NAME${NC}"
echo

# Show cost estimation
show_cost_estimation "$DATABASE" "$MODE"

# Check prerequisites
check_prerequisites "$DATABASE"

# Generate configuration
generate_config "$DATABASE" "$MODE" "$ENVIRONMENT" "$REGION" "$CLUSTER_NAME"

# Ask if user wants to deploy now
read -p "Do you want to deploy now? (yes/no): " deploy_now

if [[ "$deploy_now" == "yes" ]]; then
    run_deployment "$DATABASE"
else
    echo -e "${YELLOW}Configuration ready. To deploy later, run:${NC}"
    if [[ "$DATABASE" == "cassandra" ]]; then
        echo "cd $PROJECT_ROOT/aws-topology/cassandra-cluster"
    else
        echo "cd $PROJECT_ROOT/aws-topology/dynamodb-cluster"
    fi
    echo "terraform init && terraform plan && terraform apply"
fi

echo
echo -e "${GREEN}✅ Database deployment helper completed!${NC}"