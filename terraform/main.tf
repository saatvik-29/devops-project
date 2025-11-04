terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Random suffix to avoid naming conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Using specific Ubuntu AMI ID
locals {
  ami_id = "ami-0036347a8a8be83f1"
}

# VPC
resource "aws_vpc" "chess_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "chess-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "chess_igw" {
  vpc_id = aws_vpc.chess_vpc.id

  tags = {
    Name        = "chess-${var.environment}-igw"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "chess_public_subnet" {
  vpc_id                  = aws_vpc.chess_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "chess-${var.environment}-public-subnet"
    Environment = var.environment
  }
}

# Route Table
resource "aws_route_table" "chess_public_rt" {
  vpc_id = aws_vpc.chess_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chess_igw.id
  }

  tags = {
    Name        = "chess-${var.environment}-public-rt"
    Environment = var.environment
  }
}

# Route Table Association
resource "aws_route_table_association" "chess_public_rta" {
  subnet_id      = aws_subnet.chess_public_subnet.id
  route_table_id = aws_route_table.chess_public_rt.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group for Chess Application
resource "aws_security_group" "chess_sg" {
  name_prefix = "chess-${var.environment}-${random_id.suffix.hex}-"
  description = "Security group for Chess application"
  vpc_id      = aws_vpc.chess_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend port
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend WebSocket port
  ingress {
    from_port   = 8181
    to_port     = 8181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "chess-${var.environment}-sg"
    Environment = var.environment
  }
}

# No SSH key pair needed - using EC2 Instance Connect

# IAM Role for EC2 Instance
resource "aws_iam_role" "chess_instance_role" {
  name = "chess-${var.environment}-instance-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "chess-${var.environment}-instance-role"
    Environment = var.environment
  }
}

# Attach SSM policy to the role
resource "aws_iam_role_policy_attachment" "chess_ssm_policy" {
  role       = aws_iam_role.chess_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "chess_instance_profile" {
  name = "chess-${var.environment}-instance-profile-${random_id.suffix.hex}"
  role = aws_iam_role.chess_instance_role.name

  tags = {
    Name        = "chess-${var.environment}-instance-profile"
    Environment = var.environment
  }
}

# EC2 Instance
resource "aws_instance" "chess_app" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.chess_public_subnet.id
  vpc_security_group_ids = [aws_security_group.chess_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.chess_instance_profile.name

 user_data = <<-EOF
    #!/bin/bash
    set -e
    LOGFILE="/var/log/user-data.log"
    echo "==== User Data Script Started at $(date) ====" >> $LOGFILE 2>&1

    # Update package lists
    echo "Updating package lists..." >> $LOGFILE 2>&1
    sudo apt update -y >> $LOGFILE 2>&1

    # Install prerequisites and git
    echo "Installing prerequisites and git..." >> $LOGFILE 2>&1
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git >> $LOGFILE 2>&1

    # Add Docker GPG key and repository
    echo "Adding Docker GPG key and repository..." >> $LOGFILE 2>&1
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> $LOGFILE 2>&1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    echo "Installing Docker..." >> $LOGFILE 2>&1
    sudo apt update -y >> $LOGFILE 2>&1
    sudo apt install -y docker-ce docker-ce-cli containerd.io >> $LOGFILE 2>&1

    # Start and enable Docker
    echo "Starting and enabling Docker..." >> $LOGFILE 2>&1
    sudo systemctl start docker >> $LOGFILE 2>&1
    sudo systemctl enable docker >> $LOGFILE 2>&1

    # Install Docker Compose
    echo "Installing Docker Compose..." >> $LOGFILE 2>&1
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> $LOGFILE 2>&1
    sudo chmod +x /usr/local/bin/docker-compose >> $LOGFILE 2>&1

    # Clone Chess app repository
    echo "Cloning Chess app repository..." >> $LOGFILE 2>&1
    git clone https://github.com/saatvik-29/devops-project.git /home/ubuntu/Chess >> $LOGFILE 2>&1
    cd /home/ubuntu/Chess

    # Build and start Chess app
    echo "Building and starting Chess app with Docker Compose..." >> $LOGFILE 2>&1
    sudo docker-compose build >> $LOGFILE 2>&1
    sudo docker-compose up -d >> $LOGFILE 2>&1

    echo "==== User Data Script Completed at $(date) ====" >> $LOGFILE 2>&1
EOF



  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
  }

  tags = {
    Name        = "chess-${var.environment}-server"
    Environment = var.environment
    Application = "chess"
  }
}

# Elastic IP for consistent IP address
resource "aws_eip" "chess_eip" {
  instance = aws_instance.chess_app.id
  domain   = "vpc"

  tags = {
    Name        = "chess-${var.environment}-eip"
    Environment = var.environment
  }
}


