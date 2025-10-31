@echo off
echo ========================================
echo Checking Chess App Deployment Status
echo ========================================

set INSTANCE_IP=184.72.223.51

echo.
echo Instance IP: %INSTANCE_IP%
echo Frontend URL: http://%INSTANCE_IP%:5173
echo Backend WebSocket: ws://%INSTANCE_IP%:8181

echo.
echo Checking if frontend is accessible...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://%INSTANCE_IP%:5173' -TimeoutSec 10; Write-Host 'Frontend is accessible! Status:' $response.StatusCode } catch { Write-Host 'Frontend not yet accessible:' $_.Exception.Message }"

echo.
echo Checking if backend port is open...
powershell -Command "try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('%INSTANCE_IP%', 8181); $tcp.Close(); Write-Host 'Backend port 8181 is open!' } catch { Write-Host 'Backend port 8181 not yet accessible:' $_.Exception.Message }"

echo.
echo Note: The application may take 5-10 minutes to fully start after EC2 instance creation.
echo The user data script is installing Docker and building the application.

echo.
echo To check application logs on the instance:
echo aws ssm start-session --target i-0a122aa54a4bf4c71 --region us-east-1

pause