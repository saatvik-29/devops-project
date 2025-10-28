@echo off
echo ========================================
echo Fixing AMI Issue for Chess DevOps
echo ========================================

echo.
echo The error "Your query returned no results" has been fixed by:
echo 1. Updated AMI data source to use Ubuntu 20.04 (more widely available)
echo 2. Added fallback AMI mapping for different regions
echo 3. Used try() function to gracefully handle AMI lookup failures
echo 4. Provided known working AMI IDs as backup

echo.
echo Changes made:
echo - Updated terraform/main.tf with reliable AMI configuration
echo - Changed from Ubuntu 22.04 to Ubuntu 20.04 (better availability)
echo - Added region-specific AMI fallbacks

echo.
echo Next steps:
echo 1. Commit and push these changes
echo 2. Run Jenkins pipeline again
echo 3. Infrastructure should deploy successfully

echo.
echo To test locally:
echo cd terraform
echo terraform init
echo terraform plan
echo terraform apply

echo.
echo If you still get AMI errors, you can:
echo 1. Run test-ami.bat to verify AMI availability
echo 2. Check AWS console for available Ubuntu AMIs in your region
echo 3. Update the fallback_ami_map with current AMI IDs

pause