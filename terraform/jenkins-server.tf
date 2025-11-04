# Jenkins Server (Optional - for public webhooks)
resource "aws_instance" "jenkins_server" {
  count                  = var.deploy_jenkins ? 1 : 0
  ami                    = local.ami_id
  instance_type          = "t2.small"
  vpc_security_group_ids = [aws_security_group.jenkins_sg[0].id]
  iam_instance_profile   = aws_iam_instance_profile.chess_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    sudo apt update -y
    
    # Install Java
    sudo apt install -y openjdk-11-jdk
    
    # Install Jenkins
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update -y
    sudo apt install -y jenkins
    
    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add jenkins user to docker group
    sudo usermod -aG docker jenkins
    
    # Install Terraform
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip terraform_1.6.0_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    
    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    
    # Start Jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Get initial admin password
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /tmp/jenkins-password.txt
    sudo chmod 644 /tmp/jenkins-password.txt
  EOF

  tags = {
    Name        = "jenkins-${var.environment}-server"
    Environment = var.environment
    Application = "jenkins"
  }
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  count       = var.deploy_jenkins ? 1 : 0
  name_prefix = "jenkins-${var.environment}-"
  description = "Security group for Jenkins server"

  # Jenkins web interface
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name        = "jenkins-${var.environment}-sg"
    Environment = var.environment
  }
}

# Elastic IP for Jenkins
resource "aws_eip" "jenkins_eip" {
  count    = var.deploy_jenkins ? 1 : 0
  instance = aws_instance.jenkins_server[0].id
  domain   = "vpc"

  tags = {
    Name        = "jenkins-${var.environment}-eip"
    Environment = var.environment
  }
}