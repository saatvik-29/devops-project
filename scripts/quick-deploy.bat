@echo off
echo Quick deployment to EC2 instance...

set INSTANCE_ID=i-008703f8ee127381c
set REGION=us-east-1

echo Deploying latest code to instance %INSTANCE_ID%...

aws ssm send-command ^
    --instance-ids %INSTANCE_ID% ^
    --document-name "AWS-RunShellScript" ^
    --parameters "commands=['cd /home/ubuntu/Chess','git pull origin main','sudo docker-compose down','sudo docker-compose build','sudo docker-compose up -d']" ^
    --region %REGION%

echo Deployment command sent! Check your app in 2-3 minutes at:
echo http://54.152.24.141:5173

pause