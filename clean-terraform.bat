@echo off
echo ========================================
echo Cleaning Terraform Cache and Lock Files
echo ========================================

cd terraform

echo.
echo Removing .terraform directory...
rmdir /s /q .terraform 2>nul || echo "No .terraform directory found"

echo.
echo Removing lock file...
del .terraform.lock.hcl 2>nul || echo "No lock file found"

echo.
echo Running fresh terraform init...
terraform init

echo.
echo Running terraform plan to test...
terraform plan

echo.
echo ========================================
echo Terraform cache cleaned and reinitialized!
echo ========================================

cd ..
pause