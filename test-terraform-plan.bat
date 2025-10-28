@echo off
echo ========================================
echo Testing Terraform Plan (AMI Fix)
echo ========================================

echo.
echo Navigating to terraform directory...
cd terraform

echo.
echo Running terraform init...
terraform init

echo.
echo Running terraform plan...
terraform plan

echo.
echo If the plan succeeds without AMI errors, the fix is working!
echo If you see "Plan: X to add, 0 to change, 0 to destroy" - SUCCESS!

echo.
pause