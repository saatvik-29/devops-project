# Chess Application - CI/CD Deployment Guide

This guide explains how to set up automated CI/CD deployment for the Chess application using Jenkins and Terraform.

## 🏗️ Architecture Overview

The deployment pipeline consists of:
- **Jenkins**: CI/CD orchestration
- **Terraform**: Infrastructure as Code (IaC)
- **Docker**: Application containerization
- **AWS EC2**: Cloud infrastructure

## 📋 Prerequisites

### 1. Jenkins Setup
- Jenkins server with Docker plugin
- AWS credentials configured in Jenkins
- GitHub webhook configured

### 2. AWS Configuration
- AWS account with appropriate permissions
- EC2, VPC, and Security Group access
- AWS Systems Manager (SSM) access for deployment
- IAM role with SSM permissions for EC2 instances

### 3. Required Tools
- Terraform >= 1.0
- Docker and Docker Compose
- AWS CLI
- Git

## 🚀 Quick Start

### 1. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
aws_access_key = "your-aws-access-key"
aws_secret_key = "your-aws-secret-key"
region        = "us-east-1"
environment   = "dev"
# Note: No SSH key required - using AWS Systems Manager
```

### 2. Configure Jenkins Credentials

In Jenkins, add the following credentials:
- `aws-access-key`: Your AWS access key
- `aws-secret-key`: Your AWS secret key

### 4. Deploy Manually (Optional)

```bash
# Full deployment
./scripts/deploy.sh dev full-deployment

# Infrastructure only
./scripts/deploy.sh dev infrastructure-only

# Application only
./scripts/deploy.sh dev application-only
```

## 🔧 Jenkins Pipeline Configuration

### Pipeline Parameters

The Jenkins pipeline supports the following parameters:

| Parameter | Options | Description |
|-----------|---------|-------------|
| `DEPLOYMENT_TYPE` | `infrastructure-only`, `application-only`, `full-deployment` | Type of deployment to perform |
| `ENVIRONMENT` | `dev`, `staging`, `prod` | Target environment |
| `DESTROY_INFRASTRUCTURE` | `true`, `false` | Whether to destroy infrastructure |

### Pipeline Stages

1. **Checkout**: Pull latest code from repository
2. **Setup Tools**: Install Terraform and AWS CLI if needed
3. **Terraform Plan**: Plan infrastructure changes
4. **Terraform Apply**: Apply infrastructure changes
5. **Wait for Instance**: Wait for EC2 instance to be ready
6. **Build Docker Images**: Build and tag Docker images
7. **Deploy Application**: Deploy application to EC2 instance
8. **Health Check**: Verify application is running correctly

## 🌍 Environment Management

### Development Environment
- Instance Type: `t2.micro`
- Auto-scaling: Disabled
- Monitoring: Basic

### Staging Environment
- Instance Type: `t2.small`
- Auto-scaling: Disabled
- Monitoring: Enhanced

### Production Environment
- Instance Type: `t2.medium` or larger
- Auto-scaling: Enabled
- Monitoring: Full monitoring suite

## 📊 Monitoring and Health Checks

### Health Check Endpoints
- Frontend: `http://<instance-ip>:5173`
- Backend: `ws://<instance-ip>:8181`

### Monitoring Scripts
- `health_check.sh`: Basic health monitoring
- `monitor.sh`: Continuous monitoring with auto-restart

### Logs
- Application logs: `/home/ubuntu/app/logs/`
- System logs: `/var/log/`
- Docker logs: `docker-compose logs`

## 🔒 Security Considerations

### Network Security
- Security groups restrict access to necessary ports only
- SSH access limited to port 22
- Application ports (5173, 8181) open to all IPs

### Instance Security
- Encrypted EBS volumes
- Regular security updates via user data script
- Non-root user execution

### Access Control
- SSH key-based authentication
- IAM roles for AWS access
- Jenkins credentials management

## 🛠️ Troubleshooting

### Common Issues

1. **Terraform State Issues**
   ```bash
   cd terraform
   terraform refresh
   terraform plan
   ```

2. **Docker Build Failures**
   ```bash
   docker-compose build --no-cache
   docker system prune -f
   ```

3. **Instance Connection Issues**
   ```bash
   ssh -i ~/.ssh/chess-dev-key.pem ubuntu@<instance-ip>
   ```

4. **Application Health Issues**
   ```bash
   # Check application status
   ssh ubuntu@<instance-ip> 'cd /home/ubuntu/app && docker-compose ps'
   
   # View logs
   ssh ubuntu@<instance-ip> 'cd /home/ubuntu/app && docker-compose logs'
   ```

### Debug Commands

```bash
# Check Terraform state
cd terraform && terraform show

# Check AWS resources
aws ec2 describe-instances --filters "Name=tag:Application,Values=chess"

# Check Docker status
docker-compose ps
docker-compose logs

# Check system resources
ssh ubuntu@<instance-ip> 'htop'
```

## 📈 Scaling and Optimization

### Horizontal Scaling
- Use Application Load Balancer (ALB)
- Multiple EC2 instances
- Auto Scaling Groups

### Vertical Scaling
- Increase instance types
- Optimize Docker images
- Database optimization

### Cost Optimization
- Use Spot instances for non-critical environments
- Implement auto-shutdown for dev environments
- Monitor and optimize resource usage

## 🔄 Maintenance

### Regular Tasks
- Update AMI images
- Security patches
- Dependency updates
- Backup verification

### Backup Strategy
- EBS snapshots
- Configuration backups
- Database backups (if applicable)

## 📞 Support

For deployment issues:
1. Check Jenkins build logs
2. Review Terraform state
3. Verify AWS resource status
4. Check application logs

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
