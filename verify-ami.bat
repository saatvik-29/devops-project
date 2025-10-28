@echo off
echo ========================================
echo Verifying AMI: ami-001dd4635f9fa96b0
echo ========================================

echo.
echo Testing AMI availability in us-east-1...
aws ec2 describe-images --image-ids ami-001dd4635f9fa96b0 --region us-east-1 --query "Images[0].{Name:Name,State:State,Architecture:Architecture}" --output table

echo.
echo If you see a table with Ubuntu image details above, the AMI is valid and available!

echo.
echo Configuration updated:
echo - terraform/main.tf: Updated AMI mapping to use ami-001dd4635f9fa96b0
echo - terraform/terraform.tfvars: Set ami_id = "ami-001dd4635f9fa96b0"

echo.
echo Next step: Run Jenkins pipeline again - it should work now!

pause