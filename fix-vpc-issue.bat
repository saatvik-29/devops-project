@echo off
echo ========================================
echo Fixing VPC Issue for Chess DevOps
echo ========================================

echo.
echo The error "No default VPC for this user" has been fixed by:
echo 1. Adding VPC configuration to main.tf
echo 2. Adding Internet Gateway for public access
echo 3. Adding Public Subnet for EC2 instance
echo 4. Adding Route Table for internet routing
echo 5. Updating EC2 instance to use the new subnet

echo.
echo Next steps:
echo 1. Commit these changes to your repository
echo 2. Run the Jenkins pipeline again
echo 3. The infrastructure should deploy successfully

echo.
echo Files updated:
echo - terraform/main.tf (added VPC resources)
echo - terraform/outputs.tf (added VPC outputs)

echo.
echo To test locally:
echo cd terraform
echo terraform init
echo terraform plan
echo terraform apply

echo.
pause