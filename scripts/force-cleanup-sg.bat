@echo off
echo Force cleaning up stuck security group...

set SG_ID=sg-0b8cbc61cbe4a791b

echo Step 1: Finding instances using this security group...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=instance.group-id,Values=%SG_ID%" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query "Reservations[].Instances[].InstanceId" --output text') do (
    if not "%%i"=="" (
        echo Terminating instance %%i...
        aws ec2 terminate-instances --instance-ids %%i
    )
)

echo Step 2: Waiting 30 seconds for instances to terminate...
timeout 30 >nul

echo Step 3: Finding network interfaces using this security group...
for /f "tokens=*" %%i in ('aws ec2 describe-network-interfaces --filters "Name=group-id,Values=%SG_ID%" --query "NetworkInterfaces[].NetworkInterfaceId" --output text') do (
    if not "%%i"=="" (
        echo Detaching network interface %%i...
        aws ec2 detach-network-interface --network-interface-id %%i --force 2>nul
        echo Deleting network interface %%i...
        aws ec2 delete-network-interface --network-interface-id %%i 2>nul
    )
)

echo Step 4: Waiting 10 seconds...
timeout 10 >nul

echo Step 5: Attempting to delete security group...
aws ec2 delete-security-group --group-id %SG_ID%

echo Cleanup complete!