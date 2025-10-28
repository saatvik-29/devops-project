@echo off
REM Chess Application Deployment Script for Windows
REM Usage: deploy.bat [environment] [deployment_type]

setlocal enabledelayedexpansion

REM Default values
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=dev

set DEPLOYMENT_TYPE=%2
if "%DEPLOYMENT_TYPE%"=="" set DEPLOYMENT_TYPE=full-deployment

set TERRAFORM_DIR=terraform
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

REM Colors for output (Windows 10+)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

echo %BLUE%[INFO]%NC% Starting Chess application deployment...
echo %BLUE%[INFO]%NC% Environment: %ENVIRONMENT%
echo %BLUE%[INFO]%NC% Deployment Type: %DEPLOYMENT_TYPE%

REM Check prerequisites
echo %BLUE%[INFO]%NC% Checking prerequisites...

REM Check if terraform is installed
where terraform >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%NC% Terraform is not installed. Please install Terraform first.
    exit /b 1
)

REM Check if docker is installed
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%NC% Docker is not installed. Please install Docker first.
    exit /b 1
)

REM Check if docker-compose is installed
where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%NC% Docker Compose is not installed. Please install Docker Compose first.
    exit /b 1
)

REM Check if terraform.tfvars exists
if not exist "%PROJECT_DIR%\%TERRAFORM_DIR%\terraform.tfvars" (
    echo %RED%[ERROR]%NC% terraform.tfvars not found. Please copy terraform.tfvars.example and configure it.
    exit /b 1
)

echo %GREEN%[SUCCESS]%NC% Prerequisites check passed

REM Deploy infrastructure
if "%DEPLOYMENT_TYPE%"=="infrastructure-only" goto :deploy_infrastructure
if "%DEPLOYMENT_TYPE%"=="full-deployment" goto :deploy_infrastructure
goto :deploy_application

:deploy_infrastructure
echo %BLUE%[INFO]%NC% Deploying infrastructure for environment: %ENVIRONMENT%

cd /d "%PROJECT_DIR%\%TERRAFORM_DIR%"

REM Initialize Terraform
echo %BLUE%[INFO]%NC% Initializing Terraform...
terraform init

REM Plan deployment
echo %BLUE%[INFO]%NC% Planning Terraform deployment...
terraform plan -var="environment=%ENVIRONMENT%" -out=tfplan

REM Apply deployment
echo %BLUE%[INFO]%NC% Applying Terraform deployment...
terraform apply -auto-approve tfplan

REM Get instance IP
for /f "tokens=*" %%i in ('terraform output -raw instance_ip') do set INSTANCE_IP=%%i
echo %GREEN%[SUCCESS]%NC% Infrastructure deployed. Instance IP: !INSTANCE_IP!

cd /d "%PROJECT_DIR%"

if "%DEPLOYMENT_TYPE%"=="infrastructure-only" goto :show_summary

:deploy_application
echo %BLUE%[INFO]%NC% Deploying application...

REM Get instance IP from Terraform
cd /d "%PROJECT_DIR%\%TERRAFORM_DIR%"
for /f "tokens=*" %%i in ('terraform output -raw instance_ip') do set INSTANCE_IP=%%i
cd /d "%PROJECT_DIR%"

if "%INSTANCE_IP%"=="" (
    echo %RED%[ERROR]%NC% Could not get instance IP from Terraform
    exit /b 1
)

REM Build Docker images
echo %BLUE%[INFO]%NC% Building Docker images...
docker-compose build --no-cache

REM Tag images with timestamp
for /f "tokens=1-6 delims=: " %%a in ('echo %date% %time%') do set TIMESTAMP=%%a%%b%%c%%d%%e%%f
set TIMESTAMP=%TIMESTAMP: =0%
docker tag chess_frontend:latest chess_frontend:%TIMESTAMP%
docker tag chess_backend:latest chess_backend:%TIMESTAMP%

REM Create .env file
echo INSTANCE_IP=%INSTANCE_IP% > .env
echo WEBSOCKET_URL=ws://%INSTANCE_IP%:8181 >> .env
echo ENVIRONMENT=%ENVIRONMENT% >> .env

REM Get instance ID
cd /d "%PROJECT_DIR%\%TERRAFORM_DIR%"
for /f "tokens=*" %%i in ('terraform output -raw instance_id') do set INSTANCE_ID=%%i
cd /d "%PROJECT_DIR%"

REM Deploy on instance using AWS Systems Manager
echo %BLUE%[INFO]%NC% Deploying application on instance using AWS Systems Manager...
aws ssm send-command --instance-ids %INSTANCE_ID% --document-name "AWS-RunShellScript" --parameters "commands=['cd /home/ubuntu', 'sudo docker-compose down || true', 'sudo docker-compose pull || true', 'export WEBSOCKET_URL=ws://%INSTANCE_IP%:8181', 'sudo docker-compose up -d']" --region us-east-1

REM Wait for deployment to complete
echo %BLUE%[INFO]%NC% Waiting for deployment to complete...
timeout 60

echo %GREEN%[SUCCESS]%NC% Application deployed successfully

REM Health check
echo %BLUE%[INFO]%NC% Performing health check...

REM Wait for application to start
echo %BLUE%[INFO]%NC% Waiting for application to start...
powershell -Command "for ($i=0; $i -lt 30; $i++) { try { Invoke-WebRequest -Uri 'http://%INSTANCE_IP%:5173' -TimeoutSec 5 | Out-Null; break } catch { Write-Host 'Waiting for application to start...'; Start-Sleep 10 } }"

REM Check frontend
powershell -Command "try { Invoke-WebRequest -Uri 'http://%INSTANCE_IP%:5173' -TimeoutSec 10 | Out-Null; Write-Host 'Frontend is healthy' } catch { Write-Host 'Frontend health check failed'; exit 1 }"

REM Check backend
powershell -Command "for ($i=0; $i -lt 5; $i++) { try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('%INSTANCE_IP%', 8181); $tcp.Close(); Write-Host 'Backend is healthy'; break } catch { Write-Host 'Waiting for backend...'; Start-Sleep 2 } }"

echo %GREEN%[SUCCESS]%NC% Health check passed

:show_summary
echo.
echo ========================================
echo DEPLOYMENT SUMMARY
echo ========================================
echo Environment: %ENVIRONMENT%
echo Deployment Type: %DEPLOYMENT_TYPE%
echo Instance IP: %INSTANCE_IP%
echo Frontend URL: http://%INSTANCE_IP%:5173
echo Backend WebSocket: ws://%INSTANCE_IP%:8181
echo AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#ConnectToInstance:instanceId=%INSTANCE_ID%
echo ========================================
echo.

echo %GREEN%[SUCCESS]%NC% Deployment completed successfully!
pause
