variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

# SSH key variable removed - using EC2 Instance Connect instead

variable "git_repo" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/adnanxali/chess-devops"
}

variable "branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "deploy_jenkins" {
  description = "Whether to deploy Jenkins server"
  type        = bool
  default     = false
}

