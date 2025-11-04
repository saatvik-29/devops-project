#!/bin/bash

# Chess Application Destruction Script
# Usage: ./destroy.sh [environment]

set -e

# Default values
ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="terraform"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Confirmation prompt
confirm_destruction() {
    log_warning "This will destroy the Chess application infrastructure for environment: $ENVIRONMENT"
    log_warning "This action cannot be undone!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
}

# Destroy infrastructure
destroy_infrastructure() {
    log_info "Destroying infrastructure for environment: $ENVIRONMENT"
    
    cd "$PROJECT_DIR/$TERRAFORM_DIR"
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        log_info "Initializing Terraform..."
        terraform init
    fi
    
    # Plan destruction
    log_info "Planning infrastructure destruction..."
    terraform plan -destroy -var="environment=$ENVIRONMENT" -out=destroy.tfplan
    
    # Apply destruction
    log_info "Destroying infrastructure..."
    terraform apply -auto-approve destroy.tfplan
    
    log_success "Infrastructure destroyed successfully"
    
    cd "$PROJECT_DIR"
}

# Clean up local resources
cleanup_local() {
    log_info "Cleaning up local resources..."
    
    # Stop and remove local containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove local images
    docker rmi chess_frontend:latest chess_backend:latest 2>/dev/null || true
    
    # Clean up temporary files
    rm -f .env tfplan destroy.tfplan 2>/dev/null || true
    
    log_success "Local cleanup completed"
}

# Main destruction logic
main() {
    log_info "Starting Chess application destruction..."
    log_info "Environment: $ENVIRONMENT"
    
    confirm_destruction
    
    destroy_infrastructure
    cleanup_local
    
    log_success "Destruction completed successfully!"
    log_info "All resources for environment '$ENVIRONMENT' have been destroyed"
}

# Run main function
main "$@"
