@echo off
REM Chess Application Destruction Script for Windows
REM Usage: destroy.bat [environment]

setlocal enabledelayedexpansion

REM Default values
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=dev

set TERRAFORM_DIR=terraform
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

REM Colors for output (Windows 10+)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

echo %BLUE%[INFO]%NC% Starting Chess application destruction...
echo %BLUE%[INFO]%NC% Environment: %ENVIRONMENT%

REM Confirmation prompt
echo %YELLOW%[WARNING]%NC% This will destroy the Chess application infrastructure for environment: %ENVIRONMENT%
echo %YELLOW%[WARNING]%NC% This action cannot be undone!
echo.
set /p CONFIRM="Are you sure you want to continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo %BLUE%[INFO]%NC% Destruction cancelled
    pause
    exit /b 0
)

REM Destroy infrastructure
echo %BLUE%[INFO]%NC% Destroying infrastructure for environment: %ENVIRONMENT%

cd /d "%PROJECT_DIR%\%TERRAFORM_DIR%"

REM Initialize Terraform if needed
if not exist ".terraform" (
    echo %BLUE%[INFO]%NC% Initializing Terraform...
    terraform init
)

REM Plan destruction
echo %BLUE%[INFO]%NC% Planning infrastructure destruction...
terraform plan -destroy -var="environment=%ENVIRONMENT%" -out=destroy.tfplan

REM Apply destruction
echo %BLUE%[INFO]%NC% Destroying infrastructure...
terraform apply -auto-approve destroy.tfplan

echo %GREEN%[SUCCESS]%NC% Infrastructure destroyed successfully

cd /d "%PROJECT_DIR%"

REM Clean up local resources
echo %BLUE%[INFO]%NC% Cleaning up local resources...

REM Stop and remove local containers
docker-compose down --remove-orphans 2>nul || echo No containers to stop

REM Remove local images
docker rmi chess_frontend:latest chess_backend:latest 2>nul || echo No images to remove

REM Clean up temporary files
del tfplan destroy.tfplan .env 2>nul || echo Files not found

echo %GREEN%[SUCCESS]%NC% Local cleanup completed

echo %GREEN%[SUCCESS]%NC% Destruction completed successfully!
echo %BLUE%[INFO]%NC% All resources for environment '%ENVIRONMENT%' have been destroyed
pause
