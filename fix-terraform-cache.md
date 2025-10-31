# Fix Terraform Cache Issue

## Problem
```
Error: Required plugins are not installed
The installed provider plugins are not consistent with the packages selected in the dependency lock file
```

## Root Cause
- Terraform cache (.terraform directory) has inconsistent provider versions
- Lock file (.terraform.lock.hcl) references providers not in cache
- Jenkins workspace has stale Terraform state

## ✅ Solutions Applied

### 1. Updated Jenkinsfile
- Added cache cleanup before terraform init
- Removes .terraform directory and lock file
- Forces fresh provider download

### 2. Created Cleanup Scripts
- `clean-terraform.bat` - Manual cleanup for local testing
- Added cleanup to Jenkins post actions

### 3. Jenkins Pipeline Changes
```groovy
# Before terraform init:
rmdir /s /q .terraform 2>nul || echo "No .terraform directory"
del .terraform.lock.hcl 2>nul || echo "No lock file"
terraform init
```

## 🚀 How to Fix

### Option 1: Run Jenkins Pipeline Again
The updated Jenkinsfile will automatically clean cache and reinitialize.

### Option 2: Manual Local Fix
```bash
# Run the cleanup script
clean-terraform.bat

# Or manually:
cd terraform
rmdir /s /q .terraform
del .terraform.lock.hcl
terraform init
terraform plan
```

### Option 3: Jenkins Manual Cleanup
If Jenkins still fails, manually clean the workspace:
1. Go to Jenkins job workspace
2. Delete terraform/.terraform directory
3. Delete terraform/.terraform.lock.hcl
4. Run pipeline again

## 🔧 Prevention
- Jenkins now cleans cache on every run
- Prevents provider version conflicts
- Ensures consistent provider downloads

## ✅ Expected Result
After cleanup, you should see:
```
Initializing the backend...
Initializing provider plugins...
- Installing hashicorp/aws v5.100.0...
- Installing hashicorp/random v3.7.2...
Terraform has been successfully initialized!
```

Then the plan should work without AMI errors using your AMI: `ami-001dd4635f9fa96b0`