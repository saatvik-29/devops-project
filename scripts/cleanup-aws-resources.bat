@echo off
echo Cleaning up AWS resources for chess-dev environment...

echo Step 1: Removing role from instance profile...
aws iam remove-role-from-instance-profile --instance-profile-name chess-dev-instance-profile --role-name chess-dev-instance-role 2>nul

echo Step 2: Deleting instance profile...
aws iam delete-instance-profile --instance-profile-name chess-dev-instance-profile 2>nul

echo Step 3: Detaching policies from role...
aws iam detach-role-policy --role-name chess-dev-instance-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore 2>nul

echo Step 4: Deleting IAM role...
aws iam delete-role --role-name chess-dev-instance-role 2>nul

echo Step 5: Finding and terminating EC2 instances...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" "Name=tag:Application,Values=chess" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query "Reservations[].Instances[].InstanceId" --output text') do (
    if not "%%i"=="" (
        echo Terminating instance %%i...
        aws ec2 terminate-instances --instance-ids %%i
    )
)

echo Step 6: Finding and deleting security groups...
for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=chess-dev-*" --query "SecurityGroups[].GroupId" --output text') do (
    if not "%%i"=="" (
        echo Deleting security group %%i...
        timeout 10 >nul
        aws ec2 delete-security-group --group-id %%i 2>nul
    )
)

echo Step 7: Releasing Elastic IPs...
for /f "tokens=*" %%i in ('aws ec2 describe-addresses --filters "Name=tag:Environment,Values=dev" --query "Addresses[].AllocationId" --output text') do (
    if not "%%i"=="" (
        echo Releasing Elastic IP %%i...
        aws ec2 release-address --allocation-id %%i 2>nul
    )
)

echo Cleanup complete! Wait 2-3 minutes before running Terraform again.
pause