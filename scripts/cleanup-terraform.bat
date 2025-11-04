@echo off
echo Cleaning up Terraform state and files...

cd terraform

echo Removing Terraform state files...
del terraform.tfstate* 2>nul
del .terraform.lock.hcl 2>nul
rmdir /s /q .terraform 2>nul

echo Removing plan files...
del tfplan 2>nul
del destroy.tfplan 2>nul

echo Initializing Terraform...
terraform init

echo Terraform cleanup complete!