# Jenkins Dynamic Configuration Setup

## 🔧 Jenkins Credentials Configuration

### Step 1: Add AWS Credentials in Jenkins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** → **Add Credentials**

**AWS Access Key:**

- Kind: `Secret text`
- Secret: `Your AWS Access Key (AKIA...)`
- ID: `aws-access-key`
- Description: `AWS Access Key for Chess DevOps`

**AWS Secret Key:**

- Kind: `Secret text`
- Secret: `Your AWS Secret Access Key`
- ID: `aws-secret-key`
- Description: `AWS Secret Key for Chess DevOps`

### Step 2: Pipeline Parameters

Your pipeline now supports these dynamic parameters:

| Parameter                | Options                                                | Description            |
| ------------------------ | ------------------------------------------------------ | ---------------------- |
| `DEPLOYMENT_TYPE`        | application-only, full-deployment, infrastructure-only | Type of deployment     |
| `ENVIRONMENT`            | dev, staging, prod                                     | Target environment     |
| `AWS_REGION`             | us-east-1, us-west-2, eu-west-1, ap-south-1            | AWS region             |
| `DESTROY_INFRASTRUCTURE` | true/false                                             | Destroy infrastructure |

### Step 3: Environment Variables Passed to Terraform

The Jenkins pipeline automatically sets these Terraform variables:

```bash
TF_VAR_region = "${selected AWS_REGION}"
TF_VAR_environment = "${selected ENVIRONMENT}"
TF_VAR_aws_access_key = "${jenkins credential: aws-access-key}"
TF_VAR_aws_secret_key = "${jenkins credential: aws-secret-key}"
```

### Step 4: No terraform.tfvars Credentials Needed

Since credentials are passed dynamically from Jenkins:

- ✅ No AWS keys in terraform.tfvars
- ✅ Secure credential management
- ✅ Different credentials per environment
- ✅ Easy credential rotation

## 🚀 How to Run

### Full Deployment:

1. Click **Build with Parameters**
2. Select:
   - `DEPLOYMENT_TYPE`: `full-deployment`
   - `ENVIRONMENT`: `dev` (or staging/prod)
   - `AWS_REGION`: `us-east-1` (or your preferred region)
3. Click **Build**

### Application Only (for code updates):

1. Select `DEPLOYMENT_TYPE`: `application-only`
2. This will deploy to existing infrastructure

### Infrastructure Only:

1. Select `DEPLOYMENT_TYPE`: `infrastructure-only`
2. This will only create/update AWS resources

## 🔍 Troubleshooting

### Check Jenkins Credentials:

```groovy
// Test pipeline to verify credentials
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    stages {
        stage('Test') {
            steps {
                bat 'aws sts get-caller-identity --region us-east-1'
            }
        }
    }
}
```

### Verify Environment Variables:

The pipeline will show these in the console output:

```
TF_VAR_region=us-east-1
TF_VAR_environment=dev
TF_VAR_aws_access_key=[MASKED]
TF_VAR_aws_secret_key=[MASKED]
```

## 🔒 Security Benefits

✅ **Credentials never stored in code**
✅ **Automatic credential masking in logs**  
✅ **Centralized credential management**
✅ **Easy credential rotation**
✅ **Environment-specific configurations**
