@echo off
echo ========================================
echo Chess DevOps Local Deployment Script
echo ========================================

echo.
echo Step 1: Checking Terraform configuration...
cd terraform

echo.
echo Step 2: Initializing Terraform...
terraform init

echo.
echo Step 3: Validating configuration...
terraform validate

echo.
echo Step 4: Planning deployment...
terraform plan

echo.
echo Step 5: Applying configuration (requires confirmation)...
terraform apply

echo.
echo Step 6: Showing outputs...
terraform output

echo.
echo ========================================
echo Deployment completed!
echo ========================================
echo Frontend URL: http://%terraform output -raw instance_ip%:5173
echo Backend WebSocket: ws://%terraform output -raw instance_ip%:8181
echo ========================================

cd ..
pause