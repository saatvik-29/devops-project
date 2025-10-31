@echo off
echo ========================================
echo Deploying Chess App to EC2 Instance
echo ========================================

set INSTANCE_ID=i-0a122aa54a4bf4c71
set INSTANCE_IP=184.72.223.51

echo.
echo Instance ID: %INSTANCE_ID%
echo Instance IP: %INSTANCE_IP%

echo.
echo Sending deployment command to EC2 instance via SSM...

aws ssm send-command ^
    --instance-ids %INSTANCE_ID% ^
    --document-name "AWS-RunShellScript" ^
    --parameters "commands=['cd /home/ubuntu/Chess || (echo \"Cloning repository...\" && git clone https://github.com/saatvik-29/devops-project.git /home/ubuntu/Chess && cd /home/ubuntu/Chess)','echo \"Updating repository...\"','git fetch origin','git reset --hard origin/main','echo \"Stopping existing containers...\"','sudo docker-compose down || echo \"No containers to stop\"','echo \"Cleaning up Docker...\"','sudo docker system prune -f','echo \"Building and starting application...\"','sudo docker-compose build --no-cache','sudo docker-compose up -d --force-recreate','echo \"Deployment completed!\"','sudo docker-compose ps']" ^
    --region us-east-1

echo.
echo Deployment command sent! 
echo.
echo The application should be available in 5-10 minutes at:
echo Frontend: http://%INSTANCE_IP%:5173
echo Backend: ws://%INSTANCE_IP%:8181

echo.
echo To check deployment status, run: check-deployment.bat

pause