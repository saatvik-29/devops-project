# Note: AWS credentials are passed dynamically from Jenkins
# via TF_VAR_aws_access_key and TF_VAR_aws_secret_key environment variables

# Environment Configuration
environment   = "dev"
instance_type = "t2.micro"
volume_size   = 20

# AMI Configuration (using your working Ubuntu AMI)
ami_id = "ami-001dd4635f9fa96b0"  # Your verified working Ubuntu AMI

# Git Configuration  
git_repo = "https://github.com/saatvik-29/devops-project.git"
branch   = "main"

# Region is also passed dynamically from Jenkins via TF_VAR_region