@echo off
echo Importing existing AWS resources into Terraform state...

cd terraform

echo Initializing Terraform...
terraform init -reconfigure

echo Importing existing IAM role...
terraform import aws_iam_role.chess_instance_role chess-dev-instance-role

echo Importing existing security group...
for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=chess-dev-*" --query "SecurityGroups[0].GroupId" --output text') do set SG_ID=%%i
if defined SG_ID terraform import aws_security_group.chess_sg %SG_ID%

echo Import complete. You can now run terraform plan.