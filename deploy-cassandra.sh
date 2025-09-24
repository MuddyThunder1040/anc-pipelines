#!/bin/bash

# Cassandra Cluster Deployment Automation Script
# This script automates the complete deployment workflow for Cassandra clusters

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_DIR="aws-topology/cassandra-cluster"
DEFAULT_CONFIG_FILE="deploy-config.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_info() {
    log "${BLUE}INFO${NC}: $1"
}

log_success() {
    log "${GREEN}SUCCESS${NC}: $1"
}

log_warning() {
    log "${YELLOW}WARNING${NC}: $1"
}

log_error() {
    log "${RED}ERROR${NC}: $1"
}

# Help function
show_help() {
    cat << EOF
Cassandra Cluster Deployment Script

USAGE:
  $0 [ACTION] [OPTIONS]

ACTIONS:
  deploy     Deploy a new Cassandra cluster
  destroy    Destroy an existing cluster
  scale      Scale cluster up or down
  status     Show cluster status
  validate   Validate cluster health
  backup     Create cluster backups
  restore    Restore from backups
  help       Show this help message

OPTIONS:
  -c, --config FILE     Configuration file (default: deploy-config.env)
  -n, --name NAME       Cluster name
  -e, --env ENV         Environment (dev/staging/prod)
  -s, --size COUNT      Number of nodes (3,5,7,9)
  -t, --type TYPE       Instance type (t3.medium, m5.large, etc.)
  -r, --region REGION   AWS region
  -y, --yes             Auto-approve all prompts
  -v, --verbose         Verbose output
  --dry-run             Show what would be done without executing

EXAMPLES:
  # Deploy a 3-node development cluster
  $0 deploy --name my-cassandra --env dev --size 3

  # Scale production cluster to 5 nodes
  $0 scale --name prod-cassandra --env prod --size 5

  # Check cluster status
  $0 status --name my-cassandra

  # Destroy cluster (with confirmation)
  $0 destroy --name my-cassandra --env dev

CONFIGURATION:
  Create a deploy-config.env file with default values:
    CLUSTER_NAME=cassandra-cluster
    ENVIRONMENT=dev
    NODE_COUNT=3
    INSTANCE_TYPE=m5.large
    AWS_REGION=us-east-1
    AUTO_APPROVE=false
    ENABLE_MONITORING=true

EOF
}

# Parse command line arguments
parse_args() {
    ACTION=""
    CONFIG_FILE="$DEFAULT_CONFIG_FILE"
    CLUSTER_NAME=""
    ENVIRONMENT=""
    NODE_COUNT=""
    INSTANCE_TYPE=""
    AWS_REGION=""
    AUTO_APPROVE=false
    VERBOSE=false
    DRY_RUN=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            deploy|destroy|scale|status|validate|backup|restore|help)
                ACTION="$1"
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -n|--name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -s|--size)
                NODE_COUNT="$2"
                shift 2
                ;;
            -t|--type)
                INSTANCE_TYPE="$2"
                shift 2
                ;;
            -r|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            -y|--yes)
                AUTO_APPROVE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ -z "$ACTION" ]]; then
        log_error "Action is required"
        show_help
        exit 1
    fi
}

# Load configuration
load_config() {
    # Set defaults
    CLUSTER_NAME="${CLUSTER_NAME:-cassandra-cluster}"
    ENVIRONMENT="${ENVIRONMENT:-dev}"
    NODE_COUNT="${NODE_COUNT:-3}"
    INSTANCE_TYPE="${INSTANCE_TYPE:-m5.large}"
    AWS_REGION="${AWS_REGION:-us-east-1}"
    
    # Load from config file if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
        
        # Override with command line arguments if provided
        CLUSTER_NAME="${CLUSTER_NAME:-$CLUSTER_NAME}"
        ENVIRONMENT="${ENVIRONMENT:-$ENVIRONMENT}"
        NODE_COUNT="${NODE_COUNT:-$NODE_COUNT}"
        INSTANCE_TYPE="${INSTANCE_TYPE:-$INSTANCE_TYPE}"
        AWS_REGION="${AWS_REGION:-$AWS_REGION}"
    fi
    
    # Validate configuration
    if [[ ! "$NODE_COUNT" =~ ^[3579]$ ]]; then
        log_error "Invalid node count: $NODE_COUNT. Must be 3, 5, 7, or 9"
        exit 1
    fi
    
    log_info "Configuration loaded:"
    log_info "  Cluster: $CLUSTER_NAME-$ENVIRONMENT"
    log_info "  Nodes: $NODE_COUNT"
    log_info "  Type: $INSTANCE_TYPE"
    log_info "  Region: $AWS_REGION"
}

# Setup environment
setup_environment() {
    log_info "Setting up deployment environment..."
    
    # Check prerequisites
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed"; exit 1; }
    command -v aws >/dev/null 2>&1 || { log_error "AWS CLI is required but not installed"; exit 1; }
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    # Setup SSH key
    SSH_KEY_PATH="$HOME/.ssh/cassandra-cluster-key"
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
        chmod 600 "$SSH_KEY_PATH"
    fi
    
    # Setup directory structure
    if [[ ! -d "$CLUSTER_DIR" ]]; then
        log_info "Setting up cluster directory..."
        mkdir -p "$CLUSTER_DIR"
        
        # Try to clone from repository
        if git clone https://github.com/MuddyThunder1040/aws-topology.git /tmp/aws-topology 2>/dev/null; then
            cp -r /tmp/aws-topology/cassandra-cluster/* "$CLUSTER_DIR/"
            rm -rf /tmp/aws-topology
        else
            log_warning "Could not clone repository. Ensure Terraform files are in $CLUSTER_DIR"
        fi
    fi
    
    cd "$CLUSTER_DIR"
}

# Generate Terraform variables
generate_tf_vars() {
    log_info "Generating Terraform variables..."
    
    local public_key
    public_key=$(cat "$HOME/.ssh/cassandra-cluster-key.pub")
    
    local vpc_cidr
    case "$ENVIRONMENT" in
        prod) vpc_cidr="10.10.0.0/16" ;;
        staging) vpc_cidr="10.20.0.0/16" ;;
        *) vpc_cidr="10.30.0.0/16" ;;
    esac
    
    local data_volume_size
    case "$ENVIRONMENT" in
        prod) data_volume_size=500 ;;
        staging) data_volume_size=200 ;;
        *) data_volume_size=100 ;;
    esac
    
    local ssh_cidr
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        ssh_cidr='["10.0.0.0/8"]'  # Restrict in production
    else
        ssh_cidr='["0.0.0.0/0"]'   # Open for dev/staging
    fi
    
    cat > terraform.tfvars << EOF
# Auto-generated configuration for $CLUSTER_NAME-$ENVIRONMENT
# Generated on $(date)

# Basic Configuration
aws_region     = "$AWS_REGION"
environment    = "$ENVIRONMENT"
cluster_name   = "$CLUSTER_NAME-$ENVIRONMENT"
node_count     = $NODE_COUNT

# Instance Configuration
instance_type = "$INSTANCE_TYPE"

# Network Configuration
vpc_cidr         = "$vpc_cidr"
ssh_allowed_cidr = $ssh_cidr

# SSH Key
public_key = "$public_key"

# Storage Configuration
root_volume_size      = 20
data_volume_size      = $data_volume_size
data_volume_iops      = $([ "$ENVIRONMENT" = "prod" ] && echo "5000" || echo "3000")
data_volume_throughput = $([ "$ENVIRONMENT" = "prod" ] && echo "250" || echo "125")

# Features
assign_elastic_ips    = true
create_load_balancer  = false

# Cassandra Configuration
cassandra_version     = "4.1.3"
cassandra_heap_size   = "$(echo "$INSTANCE_TYPE" | grep -q xlarge && echo "8G" || echo "4G")"
cassandra_data_center = "dc1"

# Monitoring
enable_monitoring     = true
log_retention_days    = $([ "$ENVIRONMENT" = "prod" ] && echo "30" || echo "14")
backup_retention_days = $([ "$ENVIRONMENT" = "prod" ] && echo "30" || echo "7")

# Security
enable_encryption_at_rest    = true
enable_encryption_in_transit = $([ "$ENVIRONMENT" = "prod" ] && echo "true" || echo "false")
EOF

    log_success "Terraform variables generated"
}

# Execute deployment
execute_deploy() {
    log_info "Deploying Cassandra cluster..."
    
    terraform init
    terraform validate
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would execute terraform plan and apply"
        terraform plan
        return
    fi
    
    terraform plan -out=tfplan
    
    if [[ "$AUTO_APPROVE" != "true" ]]; then
        echo
        read -p "Do you want to apply these changes? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Deployment cancelled"
            return
        fi
    fi
    
    terraform apply tfplan
    log_success "Deployment completed!"
    
    # Show connection information
    log_info "Waiting for cluster initialization..."
    sleep 30
    
    echo
    log_info "Connection commands:"
    terraform output ssh_connection_commands || log_warning "Connection info not ready yet"
}

# Execute destroy
execute_destroy() {
    log_warning "This will destroy the entire Cassandra cluster!"
    
    if [[ "$AUTO_APPROVE" != "true" ]]; then
        echo
        read -p "Type 'DESTROY' to confirm: " -r
        if [[ "$REPLY" != "DESTROY" ]]; then
            log_info "Destruction cancelled"
            return
        fi
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would execute terraform destroy"
        terraform plan -destroy
        return
    fi
    
    terraform destroy -auto-approve
    log_success "Cluster destroyed!"
}

# Execute scaling
execute_scale() {
    log_info "Scaling cluster to $NODE_COUNT nodes..."
    
    current_count=$(terraform output -raw node_count 2>/dev/null || echo "0")
    
    if [[ "$current_count" == "$NODE_COUNT" ]]; then
        log_info "Cluster already has $NODE_COUNT nodes"
        return
    fi
    
    log_info "Current nodes: $current_count, Target nodes: $NODE_COUNT"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would scale cluster from $current_count to $NODE_COUNT nodes"
        return
    fi
    
    terraform plan -out=tfplan
    terraform apply -auto-approve tfplan
    
    log_success "Scaling completed!"
    log_info "Waiting for new nodes to join cluster..."
    sleep 60
}

# Show status
show_status() {
    log_info "Checking cluster status..."
    
    if ! terraform state list >/dev/null 2>&1; then
        log_warning "No Terraform state found. Cluster may not be deployed."
        return
    fi
    
    echo
    log_info "Terraform outputs:"
    terraform output 2>/dev/null || log_warning "No outputs available"
    
    echo
    log_info "Resource list:"
    terraform state list | head -10
    
    # Try to get cluster status from Cassandra
    if terraform output -json cassandra_public_ips >/dev/null 2>&1; then
        local first_ip
        first_ip=$(terraform output -json cassandra_public_ips | jq -r '.[0]' 2>/dev/null)
        
        if [[ "$first_ip" != "null" && -n "$first_ip" ]]; then
            log_info "Cassandra cluster status:"
            timeout 10 ssh -i "$HOME/.ssh/cassandra-cluster-key" -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
                ec2-user@"$first_ip" '/opt/cassandra/bin/nodetool status' 2>/dev/null || \
                log_warning "Could not connect to Cassandra cluster"
        fi
    fi
}

# Validate cluster
validate_cluster() {
    log_info "Validating cluster health..."
    
    if [[ -f "validate-cluster.sh" ]]; then
        chmod +x validate-cluster.sh
        ./validate-cluster.sh
    else
        log_warning "Validation script not found. Running basic checks..."
        show_status
    fi
}

# Create backups
create_backup() {
    log_info "Creating cluster backups..."
    
    if ! terraform output -json cassandra_public_ips >/dev/null 2>&1; then
        log_error "Cluster not found or not accessible"
        return 1
    fi
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    terraform output -json > "$backup_dir/terraform_outputs.json"
    cp terraform.tfvars "$backup_dir/"
    
    # Create Cassandra snapshots
    terraform output -json cassandra_public_ips | jq -r '.[]' | while read -r ip; do
        log_info "Creating snapshot on node $ip..."
        timeout 30 ssh -i "$HOME/.ssh/cassandra-cluster-key" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
            ec2-user@"$ip" '/opt/cassandra/bin/nodetool snapshot' || \
            log_warning "Failed to create snapshot on $ip"
    done
    
    log_success "Backups created in $backup_dir"
}

# Main execution function
main() {
    parse_args "$@"
    load_config
    setup_environment
    
    case "$ACTION" in
        deploy)
            generate_tf_vars
            execute_deploy
            ;;
        destroy)
            execute_destroy
            ;;
        scale)
            generate_tf_vars
            execute_scale
            ;;
        status)
            show_status
            ;;
        validate)
            validate_cluster
            ;;
        backup)
            create_backup
            ;;
        restore)
            log_error "Restore functionality not yet implemented"
            exit 1
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown action: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"