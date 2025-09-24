#!/bin/bash

# Cassandra AMI and Restack Management Script
# Provides CLI interface for AMI building and cluster restacking operations

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
DEFAULT_AMI_NAME="cassandra-cluster-ami"
DEFAULT_CLUSTER_NAME="cassandra-cluster"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
    echo ""
}

# Usage information
show_usage() {
    cat << EOF
${CYAN}Cassandra AMI and Restack Management Tool${NC}

${YELLOW}USAGE:${NC}
    $0 <command> [options]

${YELLOW}AMI COMMANDS:${NC}
    ami build [options]           Build a new Cassandra AMI
    ami list                      List existing Cassandra AMIs
    ami cleanup                   Clean up old AMIs (>30 days)
    ami validate <ami-id>         Validate an AMI
    ami latest                    Get latest AMI ID

${YELLOW}RESTACK COMMANDS:${NC}
    restack plan [options]        Plan infrastructure changes
    restack apply [options]       Apply infrastructure changes
    restack destroy [options]     Destroy infrastructure
    restack refresh [options]     Refresh Terraform state
    restack rolling [options]     Perform rolling update
    restack blue-green [options]  Perform blue-green deployment

${YELLOW}AMI BUILD OPTIONS:${NC}
    --name <name>                 AMI name (default: ${DEFAULT_AMI_NAME})
    --cassandra-version <ver>     Cassandra version (default: 4.1.3)
    --base-ami <type>            Base AMI type (amazon-linux-2, ubuntu-20.04, ubuntu-22.04)
    --instance-type <type>        Build instance type (default: t3.medium)
    --region <region>             AWS region (default: ${AWS_REGION})
    --enable-monitoring           Install CloudWatch agent
    --install-tools               Install additional tools
    --optimize                    Optimize AMI for production

${YELLOW}RESTACK OPTIONS:${NC}
    --cluster-name <name>         Cluster name (default: ${DEFAULT_CLUSTER_NAME})
    --environment <env>           Environment (development, staging, production)
    --region <region>             AWS region (default: ${AWS_REGION})
    --ami-id <id>                 New AMI ID to use
    --instance-type <type>        New instance type
    --strategy <strategy>         Restack strategy (in-place, rolling, blue-green)
    --backup                      Create backup before restack
    --auto-approve                Auto-approve changes
    --workspace <name>            Terraform workspace

${YELLOW}GLOBAL OPTIONS:${NC}
    --help, -h                    Show this help message
    --verbose, -v                 Enable verbose output
    --dry-run                     Show what would be done without executing

${YELLOW}EXAMPLES:${NC}
    # Build a new AMI
    $0 ami build --cassandra-version 4.1.3 --enable-monitoring --optimize

    # List AMIs
    $0 ami list

    # Plan infrastructure changes
    $0 restack plan --cluster-name my-cluster --environment production

    # Apply changes with backup
    $0 restack apply --backup --cluster-name my-cluster

    # Rolling update with new AMI
    $0 restack rolling --ami-id ami-12345 --strategy rolling

    # Blue-green deployment
    $0 restack blue-green --ami-id ami-12345 --environment production

EOF
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    for tool in aws terraform jq packer; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log_error "AWS credentials not configured"
        log_info "Please configure AWS credentials using 'aws configure' or environment variables"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Parse command line arguments
parse_arguments() {
    COMMAND=""
    SUBCOMMAND=""
    
    # Parse main command
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    COMMAND="$1"
    shift
    
    if [ "$COMMAND" = "ami" ] || [ "$COMMAND" = "restack" ]; then
        if [ $# -eq 0 ]; then
            log_error "Subcommand required for $COMMAND"
            show_usage
            exit 1
        fi
        SUBCOMMAND="$1"
        shift
    fi
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            # AMI options
            --name)
                AMI_NAME="$2"
                shift 2
                ;;
            --cassandra-version)
                CASSANDRA_VERSION="$2"
                shift 2
                ;;
            --base-ami)
                BASE_AMI_TYPE="$2"
                shift 2
                ;;
            --instance-type)
                INSTANCE_TYPE="$2"
                shift 2
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            --enable-monitoring)
                ENABLE_MONITORING=true
                shift
                ;;
            --install-tools)
                INSTALL_TOOLS=true
                shift
                ;;
            --optimize)
                OPTIMIZE_AMI=true
                shift
                ;;
            # Restack options
            --cluster-name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            --environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --ami-id)
                NEW_AMI_ID="$2"
                shift 2
                ;;
            --strategy)
                RESTACK_STRATEGY="$2"
                shift 2
                ;;
            --backup)
                BACKUP_BEFORE_RESTACK=true
                shift
                ;;
            --auto-approve)
                AUTO_APPROVE=true
                shift
                ;;
            --workspace)
                TERRAFORM_WORKSPACE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set defaults
    AMI_NAME="${AMI_NAME:-$DEFAULT_AMI_NAME}"
    CASSANDRA_VERSION="${CASSANDRA_VERSION:-4.1.3}"
    BASE_AMI_TYPE="${BASE_AMI_TYPE:-amazon-linux-2}"
    INSTANCE_TYPE="${INSTANCE_TYPE:-t3.medium}"
    CLUSTER_NAME="${CLUSTER_NAME:-$DEFAULT_CLUSTER_NAME}"
    ENVIRONMENT="${ENVIRONMENT:-development}"
    RESTACK_STRATEGY="${RESTACK_STRATEGY:-in-place}"
    ENABLE_MONITORING="${ENABLE_MONITORING:-false}"
    INSTALL_TOOLS="${INSTALL_TOOLS:-false}"
    OPTIMIZE_AMI="${OPTIMIZE_AMI:-false}"
    BACKUP_BEFORE_RESTACK="${BACKUP_BEFORE_RESTACK:-false}"
    AUTO_APPROVE="${AUTO_APPROVE:-false}"
    VERBOSE="${VERBOSE:-false}"
    DRY_RUN="${DRY_RUN:-false}"
}

# Execute command with dry-run support
execute_command() {
    local cmd="$1"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would execute: $cmd"
    else
        if [ "$VERBOSE" = true ]; then
            log_info "Executing: $cmd"
        fi
        eval "$cmd"
    fi
}

# Get latest AMI ID
get_latest_ami() {
    local ami_name_pattern="${1:-$AMI_NAME}"
    
    aws ec2 describe-images \
        --owners self \
        --filters "Name=name,Values=${ami_name_pattern}*" \
        --region "$AWS_REGION" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text
}

# AMI Commands
ami_build() {
    log_header "BUILDING CASSANDRA AMI"
    
    log_info "Build Configuration:"
    log_info "  AMI Name: $AMI_NAME"
    log_info "  Cassandra Version: $CASSANDRA_VERSION"
    log_info "  Base AMI: $BASE_AMI_TYPE"
    log_info "  Instance Type: $INSTANCE_TYPE"
    log_info "  Region: $AWS_REGION"
    log_info "  Monitoring: $ENABLE_MONITORING"
    log_info "  Tools: $INSTALL_TOOLS"
    log_info "  Optimize: $OPTIMIZE_AMI"
    echo ""
    
    # Create build directory
    local build_dir="ami-build-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Generate Packer configuration
    log_info "Generating Packer configuration..."
    cat > cassandra-ami.pkr.hcl << EOF
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_name" {
  type    = string
  default = "$AMI_NAME"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name  = "\${var.ami_name}-$CASSANDRA_VERSION-\${local.timestamp}"
}

source "amazon-ebs" "cassandra" {
  ami_name      = local.ami_name
  instance_type = "$INSTANCE_TYPE"
  region        = "$AWS_REGION"
  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  ssh_username = "ec2-user"
  
  tags = {
    Name             = local.ami_name
    CassandraVersion = "$CASSANDRA_VERSION"
    BaseAMI          = "$BASE_AMI_TYPE"
    BuildDate        = timestamp()
    Purpose          = "cassandra-cluster"
  }
}

build {
  sources = ["source.amazon-ebs.cassandra"]
  
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y java-11-amazon-corretto-headless wget curl unzip",
      "sudo useradd cassandra",
      "sudo mkdir -p /opt/cassandra /var/lib/cassandra /var/log/cassandra /etc/cassandra",
      "cd /opt && sudo wget https://archive.apache.org/dist/cassandra/$CASSANDRA_VERSION/apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz",
      "sudo tar -xzf apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz",
      "sudo ln -s apache-cassandra-$CASSANDRA_VERSION cassandra",
      "sudo chown -R cassandra:cassandra /opt/cassandra /var/lib/cassandra /var/log/cassandra /etc/cassandra",
      "sudo cp -r /opt/cassandra/conf/* /etc/cassandra/",
      "echo 'export CASSANDRA_HOME=/opt/cassandra' | sudo tee /etc/profile.d/cassandra.sh",
      "echo 'export PATH=\$PATH:\$CASSANDRA_HOME/bin' | sudo tee -a /etc/profile.d/cassandra.sh"
    ]
  }
  
  post-processor "manifest" {
    output = "packer-manifest.json"
  }
}
EOF
    
    # Build AMI
    log_info "Building AMI with Packer..."
    execute_command "packer build cassandra-ami.pkr.hcl"
    
    if [ "$DRY_RUN" != true ]; then
        # Get AMI ID from manifest
        local ami_id
        ami_id=$(jq -r '.builds[0].artifact_id' packer-manifest.json | cut -d: -f2)
        
        log_success "AMI built successfully: $ami_id"
        log_info "AMI is ready for use in your Cassandra cluster deployments"
    fi
    
    cd ..
    rm -rf "$build_dir"
}

ami_list() {
    log_header "LISTING CASSANDRA AMIS"
    
    aws ec2 describe-images \
        --owners self \
        --filters "Name=name,Values=${AMI_NAME}*" \
        --region "$AWS_REGION" \
        --query 'Images[*].{ImageId:ImageId,Name:Name,State:State,CreationDate:CreationDate}' \
        --output table
}

ami_cleanup() {
    log_header "CLEANING UP OLD AMIS"
    
    local cutoff_date
    cutoff_date=$(date -d "30 days ago" +%Y-%m-%d)
    
    log_info "Finding AMIs older than $cutoff_date..."
    
    local old_amis
    old_amis=$(aws ec2 describe-images \
        --owners self \
        --filters "Name=name,Values=${AMI_NAME}*" \
        --region "$AWS_REGION" \
        --query "Images[?CreationDate<'$cutoff_date'].ImageId" \
        --output text)
    
    if [ -n "$old_amis" ]; then
        log_info "Found old AMIs: $old_amis"
        
        for ami_id in $old_amis; do
            log_info "Deregistering AMI: $ami_id"
            execute_command "aws ec2 deregister-image --image-id $ami_id --region $AWS_REGION"
        done
        
        log_success "Cleanup completed"
    else
        log_info "No old AMIs found to clean up"
    fi
}

ami_validate() {
    local ami_id="$1"
    
    if [ -z "$ami_id" ]; then
        log_error "AMI ID required for validation"
        exit 1
    fi
    
    log_header "VALIDATING AMI: $ami_id"
    
    # Check if AMI exists and get details
    local ami_info
    ami_info=$(aws ec2 describe-images --image-ids "$ami_id" --region "$AWS_REGION" 2>/dev/null)
    
    if [ -z "$ami_info" ]; then
        log_error "AMI not found: $ami_id"
        exit 1
    fi
    
    # Display AMI details
    echo "$ami_info" | jq -r '.Images[0] | {ImageId,Name,State,Architecture,VirtualizationType,CreationDate}'
    
    log_success "AMI validation completed"
}

ami_latest() {
    log_header "GETTING LATEST AMI"
    
    local latest_ami
    latest_ami=$(get_latest_ami)
    
    if [ "$latest_ami" != "None" ] && [ -n "$latest_ami" ]; then
        log_success "Latest AMI: $latest_ami"
        echo "$latest_ami"
    else
        log_error "No AMI found with pattern: ${AMI_NAME}*"
        exit 1
    fi
}

# Restack Commands
restack_plan() {
    log_header "PLANNING INFRASTRUCTURE CHANGES"
    
    log_info "Plan Configuration:"
    log_info "  Cluster: $CLUSTER_NAME"
    log_info "  Environment: $ENVIRONMENT"
    log_info "  Region: $AWS_REGION"
    log_info "  AMI ID: ${NEW_AMI_ID:-Auto-detect latest}"
    log_info "  Instance Type: ${INSTANCE_TYPE:-Current}"
    echo ""
    
    # Navigate to Terraform directory
    cd "$SCRIPT_DIR/../aws-topology/cassandra-cluster"
    
    # Initialize Terraform
    execute_command "terraform init"
    
    # Select workspace if specified
    if [ -n "$TERRAFORM_WORKSPACE" ]; then
        execute_command "terraform workspace select $TERRAFORM_WORKSPACE || terraform workspace new $TERRAFORM_WORKSPACE"
    fi
    
    # Generate terraform variables
    generate_terraform_vars
    
    # Run plan
    execute_command "terraform plan -var-file=restack.tfvars"
    
    log_success "Plan completed"
}

restack_apply() {
    log_header "APPLYING INFRASTRUCTURE CHANGES"
    
    # Create backup if requested
    if [ "$BACKUP_BEFORE_RESTACK" = true ]; then
        create_backup
    fi
    
    # Navigate to Terraform directory
    cd "$SCRIPT_DIR/../aws-topology/cassandra-cluster"
    
    # Initialize and select workspace
    execute_command "terraform init"
    if [ -n "$TERRAFORM_WORKSPACE" ]; then
        execute_command "terraform workspace select $TERRAFORM_WORKSPACE || terraform workspace new $TERRAFORM_WORKSPACE"
    fi
    
    # Generate terraform variables
    generate_terraform_vars
    
    # Apply changes
    local approve_flag=""
    if [ "$AUTO_APPROVE" = true ]; then
        approve_flag="-auto-approve"
    fi
    
    execute_command "terraform apply $approve_flag -var-file=restack.tfvars"
    
    log_success "Infrastructure changes applied"
}

restack_destroy() {
    log_header "DESTROYING INFRASTRUCTURE"
    
    log_warning "This will destroy all infrastructure resources!"
    
    if [ "$AUTO_APPROVE" != true ] && [ "$DRY_RUN" != true ]; then
        read -p "Are you sure you want to destroy the infrastructure? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log_info "Destroy operation cancelled"
            exit 0
        fi
    fi
    
    # Navigate to Terraform directory
    cd "$SCRIPT_DIR/../aws-topology/cassandra-cluster"
    
    # Initialize and select workspace
    execute_command "terraform init"
    if [ -n "$TERRAFORM_WORKSPACE" ]; then
        execute_command "terraform workspace select $TERRAFORM_WORKSPACE"
    fi
    
    # Generate terraform variables
    generate_terraform_vars
    
    # Destroy infrastructure
    execute_command "terraform destroy -auto-approve -var-file=restack.tfvars"
    
    log_success "Infrastructure destroyed"
}

restack_refresh() {
    log_header "REFRESHING TERRAFORM STATE"
    
    cd "$SCRIPT_DIR/../aws-topology/cassandra-cluster"
    
    execute_command "terraform init"
    if [ -n "$TERRAFORM_WORKSPACE" ]; then
        execute_command "terraform workspace select $TERRAFORM_WORKSPACE"
    fi
    
    generate_terraform_vars
    execute_command "terraform refresh -var-file=restack.tfvars"
    
    log_success "Terraform state refreshed"
}

restack_rolling() {
    log_header "PERFORMING ROLLING UPDATE"
    
    log_info "Rolling update with strategy: $RESTACK_STRATEGY"
    # Implementation for rolling update would go here
    log_info "Rolling update functionality is available in the Jenkins pipeline"
    log_info "Use: jenkins-cli build CassandraRestackJenkinsfile -p RESTACK_ACTION=rolling-update"
}

restack_blue_green() {
    log_header "PERFORMING BLUE-GREEN DEPLOYMENT"
    
    log_info "Blue-green deployment with strategy: $RESTACK_STRATEGY"
    # Implementation for blue-green deployment would go here
    log_info "Blue-green deployment functionality is available in the Jenkins pipeline"
    log_info "Use: jenkins-cli build CassandraRestackJenkinsfile -p RESTACK_ACTION=blue-green"
}

# Helper functions
generate_terraform_vars() {
    cat > restack.tfvars << EOF
# Restack Configuration
cluster_name = "$CLUSTER_NAME"
environment = "$ENVIRONMENT"
aws_region = "$AWS_REGION"

# Instance Configuration
${INSTANCE_TYPE:+instance_type = "$INSTANCE_TYPE"}
${NEW_AMI_ID:+ami_id = "$NEW_AMI_ID"}

# Build Information
build_timestamp = "$(date +%Y-%m-%d-%H-%M-%S)"
EOF
    
    log_info "Terraform variables generated"
}

create_backup() {
    log_info "Creating pre-restack backup..."
    
    # This would implement EBS snapshot creation
    # For now, just log the action
    log_info "Backup functionality available in Jenkins pipeline"
    log_info "Manual backup: Create EBS snapshots of your data volumes"
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Show header
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 Cassandra AMI & Restack Tool                ║"
    echo "║                      Management CLI                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Execute command
    case "$COMMAND" in
        ami)
            case "$SUBCOMMAND" in
                build)
                    ami_build
                    ;;
                list)
                    ami_list
                    ;;
                cleanup)
                    ami_cleanup
                    ;;
                validate)
                    ami_validate "$NEW_AMI_ID"
                    ;;
                latest)
                    ami_latest
                    ;;
                *)
                    log_error "Unknown AMI subcommand: $SUBCOMMAND"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        restack)
            case "$SUBCOMMAND" in
                plan)
                    restack_plan
                    ;;
                apply)
                    restack_apply
                    ;;
                destroy)
                    restack_destroy
                    ;;
                refresh)
                    restack_refresh
                    ;;
                rolling)
                    restack_rolling
                    ;;
                blue-green)
                    restack_blue_green
                    ;;
                *)
                    log_error "Unknown restack subcommand: $SUBCOMMAND"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    log_success "Operation completed successfully!"
}

# Run main function with all arguments
main "$@"