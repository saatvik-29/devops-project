@echo off
echo ========================================
echo Testing AMI Availability
echo ========================================

echo.
echo Testing AMI in us-east-1...
aws ec2 describe-images --image-ids ami-0e86e20dae9224db8 --region us-east-1 --query "Images[0].Name" --output text

echo.
echo If the above shows an Ubuntu image name, the AMI is valid.
echo If it shows "None" or errors, we need to update the AMI ID.

echo.
echo You can find the latest Ubuntu AMI IDs at:
echo https://cloud-images.ubuntu.com/locator/ec2/

pause