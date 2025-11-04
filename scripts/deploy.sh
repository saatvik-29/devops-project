#!/bin/bash

# Chess Application Deployment Script
# Usage: ./deploy.sh [environment] [deployment_type]

set -e

# Default values
ENVIRONMENT=${1:-dev}
DEPLOYMENT_TYPE=${2:-full-deployment}
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "$PROJECT_DIR/$TERRAFORM_DIR/terraform.tfvars" ]; then
        log_error "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure for environment: $ENVIRONMENT"
    
    cd "$PROJECT_DIR/$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -var="environment=$ENVIRONMENT" -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply -auto-approve tfplan
    
    # Get instance IP
    INSTANCE_IP=$(terraform output -raw instance_ip)
    log_success "Infrastructure deployed. Instance IP: $INSTANCE_IP"
    
    cd "$PROJECT_DIR"
}

# Deploy application
deploy_application() {
    log_info "Deploying application..."
    
    # Get instance IP from Terraform
    INSTANCE_IP=$(cd "$PROJECT_DIR/$TERRAFORM_DIR" && terraform output -raw instance_ip)
    
    if [ -z "$INSTANCE_IP" ]; then
        log_error "Could not get instance IP from Terraform"
        exit 1
    fi
    
    # Build Docker images
    log_info "Building Docker images..."
    docker-compose build --no-cache
    
    # Tag images with timestamp
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    docker tag chess_frontend:latest chess_frontend:$TIMESTAMP
    docker tag chess_backend:latest chess_backend:$TIMESTAMP
    
    # Create .env file
    cat > .env << EOF
INSTANCE_IP=$INSTANCE_IP
WEBSOCKET_URL=ws://$INSTANCE_IP:8181
ENVIRONMENT=$ENVIRONMENT
EOF
    
    # Copy files to instance
    log_info "Copying files to instance..."
    scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@$INSTANCE_IP:/home/ubuntu/
    scp -o StrictHostKeyChecking=no .env ubuntu@$INSTANCE_IP:/home/ubuntu/ 2>/dev/null || true
    
    # Deploy on instance
    log_info "Deploying application on instance..."
    ssh -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "
        cd /home/ubuntu
        export WEBSOCKET_URL=ws://$INSTANCE_IP:8181
        sudo docker-compose down || true
        sudo docker-compose pull || true
        sudo docker-compose up -d
    "
    
    log_success "Application deployed successfully"
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    INSTANCE_IP=$(cd "$PROJECT_DIR/$TERRAFORM_DIR" && terraform output -raw instance_ip)
    
    # Wait for application to start
    log_info "Waiting for application to start..."
    timeout 300 bash -c "until curl -f http://$INSTANCE_IP:5173 > /dev/null 2>&1; do
        echo 'Waiting for application to start...'
        sleep 10
    done"
    
    # Check frontend
    if curl -f http://$INSTANCE_IP:5173 > /dev/null 2>&1; then
        log_success "Frontend is healthy"
    else
        log_error "Frontend health check failed"
        exit 1
    fi
    
    # Check backend
    if timeout 10 bash -c "until nc -z $INSTANCE_IP 8181; do sleep 2; done"; then
        log_success "Backend is healthy"
    else
        log_error "Backend health check failed"
        exit 1
    fi
    
    log_success "Health check passed"
}

# Show deployment summary
show_summary() {
    INSTANCE_IP=$(cd "$PROJECT_DIR/$TERRAFORM_DIR" && terraform output -raw instance_ip)
    
    echo ""
    echo "========================================"
    echo "DEPLOYMENT SUMMARY"
    echo "========================================"
    echo "Environment: $ENVIRONMENT"
    echo "Deployment Type: $DEPLOYMENT_TYPE"
    echo "Instance IP: $INSTANCE_IP"
    echo "Frontend URL: http://$INSTANCE_IP:5173"
    echo "Backend WebSocket: ws://$INSTANCE_IP:8181"
    echo "SSH Command: ssh -i ~/.ssh/chess-$ENVIRONMENT-key.pem ubuntu@$INSTANCE_IP"
    echo "========================================"
    echo ""
}

# Main deployment logic
main() {
    log_info "Starting Chess application deployment..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Deployment Type: $DEPLOYMENT_TYPE"
    
    check_prerequisites
    
    case $DEPLOYMENT_TYPE in
        "infrastructure-only")
            deploy_infrastructure
            ;;
        "application-only")
            deploy_application
            health_check
            ;;
        "full-deployment")
            deploy_infrastructure
            deploy_application
            health_check
            ;;
        *)
            log_error "Invalid deployment type: $DEPLOYMENT_TYPE"
            log_info "Valid options: infrastructure-only, application-only, full-deployment"
            exit 1
            ;;
    esac
    
    show_summary
    log_success "Deployment completed successfully!"
}

# Run main function
main "$@"
