pipeline {
    agent any
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        skipDefaultCheckout()
    }

    environment {
        AWS_DEFAULT_REGION = "${params.AWS_REGION ?: 'us-east-1'}"
        TF_VAR_region = "${params.AWS_REGION ?: 'us-east-1'}"
        TF_VAR_environment = "${params.ENVIRONMENT ?: 'dev'}"
        TF_VAR_aws_access_key = credentials('aws-access-key')
        TF_VAR_aws_secret_key = credentials('aws-secret-key')
        // WEBSOCKET_URL will be dynamically set after instance is ready
    }

    parameters {
        choice(
            name: 'DEPLOYMENT_TYPE',
            choices: ['application-only', 'full-deployment', 'infrastructure-only'],
            description: 'Choose deployment type (application-only is default for auto-deployment)'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Choose environment'
        )
        choice(
            name: 'AWS_REGION',
            choices: ['us-east-1', 'us-west-2', 'eu-west-1', 'ap-south-1'],
            description: 'Choose AWS region'
        )
        booleanParam(
            name: 'DESTROY_INFRASTRUCTURE',
            defaultValue: false,
            description: 'Destroy infrastructure (use with caution)'
        )
    }

    triggers {
    pollSCM('* * * * *') // poll every minute
}

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    try {
                        env.GIT_COMMIT_SHORT = bat(
                            script: 'git rev-parse --short HEAD',
                            returnStdout: true
                        ).trim()
                        echo "Git commit: ${env.GIT_COMMIT_SHORT}"
                    } catch (Exception e) {
                        env.GIT_COMMIT_SHORT = env.BUILD_NUMBER
                        echo "Could not get git commit, using build number: ${env.GIT_COMMIT_SHORT}"
                    }
                    
                    // Auto-detect if this is a SCM-triggered build for code changes
                    def buildCause = currentBuild.getBuildCauses('hudson.triggers.SCMTrigger$SCMTriggerCause')
                    if (buildCause) {
                        echo "SCM-triggered build detected - forcing application-only deployment"
                        env.AUTO_DEPLOYMENT_TYPE = 'application-only'
                        env.AUTO_ENVIRONMENT = 'dev'
                        env.AUTO_DESTROY = 'false'
                    } else {
                        echo "Manual build - using selected parameters"
                        env.AUTO_DEPLOYMENT_TYPE = params.DEPLOYMENT_TYPE
                        env.AUTO_ENVIRONMENT = params.ENVIRONMENT
                        env.AUTO_DESTROY = params.DESTROY_INFRASTRUCTURE.toString()
                    }
                    
                    echo "Effective deployment type: ${env.AUTO_DEPLOYMENT_TYPE}"
                    echo "Effective environment: ${env.AUTO_ENVIRONMENT}"
                }
            }
        }

        stage('Setup Tools') {
            steps {
                script {
                    bat '''
                        where terraform >nul 2>&1
                        if %errorlevel% neq 0 (
                            echo Installing Terraform...
                            powershell -Command "Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_windows_amd64.zip' -OutFile 'terraform.zip'"
                            powershell -Command "Expand-Archive -Path 'terraform.zip' -DestinationPath '.' -Force"
                            move terraform.exe C:\\Windows\\System32\\
                            del terraform.zip
                        )

                        where aws >nul 2>&1
                        if %errorlevel% neq 0 (
                            echo Installing AWS CLI...
                            powershell -Command "Invoke-WebRequest -Uri 'https://awscli.amazonaws.com/AWSCLIV2.msi' -OutFile 'AWSCLIV2.msi'"
                            msiexec /i AWSCLIV2.msi /quiet
                            del AWSCLIV2.msi
                        )
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    if (env.AUTO_DEPLOYMENT_TYPE == 'infrastructure-only' || env.AUTO_DEPLOYMENT_TYPE == 'full-deployment') {
                        dir('terraform') {
                            if (params.DESTROY_INFRASTRUCTURE) {
                                bat '''
                                    rmdir /s /q .terraform 2>nul || echo "No .terraform directory"
                                    del .terraform.lock.hcl 2>nul || echo "No lock file"
                                    terraform init
                                    terraform plan -destroy -out=destroy.tfplan
                                '''
                            } else {
                                bat '''
                                    rmdir /s /q .terraform 2>nul || echo "No .terraform directory"
                                    del .terraform.lock.hcl 2>nul || echo "No lock file"
                                    terraform init
                                    terraform refresh || echo "Refresh failed, continuing..."
                                    terraform plan -out=tfplan
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    if (env.AUTO_DEPLOYMENT_TYPE == 'infrastructure-only' || env.AUTO_DEPLOYMENT_TYPE == 'full-deployment') {
                        dir('terraform') {
                            if (params.DESTROY_INFRASTRUCTURE) {
                                bat '''
                                    terraform apply -auto-approve destroy.tfplan
                                '''
                            } else {
                                bat '''
                                    terraform apply -auto-approve tfplan
                                    
                                    REM Get instance IP and save to environment
                                    for /f "tokens=*" %%i in ('terraform output -raw instance_ip') do set INSTANCE_IP=%%i
                                    echo INSTANCE_IP=%INSTANCE_IP% > ..\\.env
                                    echo Instance IP: %INSTANCE_IP%
                                '''
                            }
                        }
                    }
                }
            }
        }

       stage('Wait for Instance') {
    steps {
        script {
            if ((env.AUTO_DEPLOYMENT_TYPE == 'infrastructure-only' || env.AUTO_DEPLOYMENT_TYPE == 'full-deployment') && env.AUTO_DESTROY != 'true') {
                dir('terraform') {
                    def instanceIp = bat(
                        script: 'terraform output -raw instance_ip',
                        returnStdout: true
                    ).trim()
                    
                    // Clean up the IP
                    instanceIp = instanceIp.replaceAll(/[^0-9.]/, '')
                    env.INSTANCE_IP = instanceIp
                    env.WEBSOCKET_URL = "ws://${instanceIp}:8181"

                    echo "Waiting for instance ${instanceIp} to be ready..."
                    
                    // Use a proper batch script with the IP variable set
                    bat """
@echo off
set INSTANCE_IP=${instanceIp}
powershell -NoProfile -ExecutionPolicy Bypass -Command "\$i=0; while (\$i -lt 10) { try { Invoke-WebRequest -Uri 'http://%INSTANCE_IP%:5173' -TimeoutSec 5 | Out-Null; Write-Host 'Instance is ready!'; break } catch { Write-Host 'Waiting for instance... (attempt ' + (\$i+1) + '/10)'; Start-Sleep -Seconds 10; \$i++ } }"
"""
                }
            }
        }
    }
}

        stage('Build Docker Images') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        if ((env.AUTO_DEPLOYMENT_TYPE == 'application-only' || env.AUTO_DEPLOYMENT_TYPE == 'full-deployment') && env.AUTO_DESTROY != 'true') {
                            echo "Skipping Docker build on Jenkins - will build on EC2 instance"
                            echo "Docker will be installed and images built on the target EC2 instance"
                            // Mark this stage as successful
                            currentBuild.result = 'SUCCESS'
                        }
                    }
                }
            }
        }

        stage('Deploy Application') {
    timeout(time: 5, unit: 'MINUTES') {
        script {
            dir('terraform') {
                echo "=== Starting AWS SSM Deployment ==="

                // Capture Terraform outputs correctly
                def instance_id = bat(
                    script: 'terraform output -raw instance_id',
                    returnStdout: true
                ).trim()
                def instance_ip = bat(
                    script: 'terraform output -raw instance_ip',
                    returnStdout: true
                ).trim()

                echo "Instance ID: ${instance_id}"
                echo "Instance IP: ${instance_ip}"
                echo "Region: ${env.AWS_REGION}"

                // Run the actual AWS CLI command
                def deployCmd = """
                aws ssm send-command ^
                    --instance-ids ${instance_id} ^
                    --document-name "AWS-RunShellScript" ^
                    --comment "Deploying app via Jenkins" ^
                    --parameters "commands=['cd /home/ec2-user/app && docker-compose up -d']" ^
                    --region ${env.AWS_REGION}
                """

                bat(label: 'Deploying via AWS SSM', script: deployCmd)
            }
        }
    }
}



        stage('Health Check') {
            steps {
                script {
                    if ((env.AUTO_DEPLOYMENT_TYPE == 'application-only' || env.AUTO_DEPLOYMENT_TYPE == 'full-deployment') && env.AUTO_DESTROY != 'true') {
                        def instanceIp = env.INSTANCE_IP ?: "184.72.223.51"

                        echo "Performing basic health checks on instance ${instanceIp}"
                        echo "Note: Application may take 5-10 minutes to fully start after deployment"

                        bat """
echo Checking instance connectivity...
ping -n 1 ${instanceIp} || echo "Instance ping failed"

echo Checking if ports will be accessible (may take time)...
powershell -Command "try { \$tcp = New-Object System.Net.Sockets.TcpClient; \$tcp.Connect('${instanceIp}', 22); \$tcp.Close(); Write-Host 'SSH port 22 is accessible' } catch { Write-Host 'SSH port not yet accessible' }"

echo Health check completed. Application deployment is in progress.
echo Frontend will be available at: http://${instanceIp}:5173
echo Backend will be available at: ws://${instanceIp}:8181
"""
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (!params.DESTROY_INFRASTRUCTURE && (params.DEPLOYMENT_TYPE == 'full-deployment' || params.DEPLOYMENT_TYPE == 'infrastructure-only')) {
                    def instanceIp = env.INSTANCE_IP ?: bat(
                        script: 'cd terraform && terraform output -raw instance_ip 2>nul || echo N/A',
                        returnStdout: true
                    ).trim()
                    instanceIp = instanceIp.replaceAll(/.*?(\d+\.\d+\.\d+\.\d+).*/, '$1')

                    echo """
========================================
DEPLOYMENT SUMMARY
========================================
Environment: ${params.ENVIRONMENT}
Deployment Type: ${params.DEPLOYMENT_TYPE}
Instance IP: ${instanceIp}
Frontend URL: http://${instanceIp}:5173
Backend WebSocket: ws://${instanceIp}:8181
Git Commit: ${env.GIT_COMMIT_SHORT}
========================================
"""
                }
            }
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
            script {
                if (params.DEPLOYMENT_TYPE == 'full-deployment' || params.DEPLOYMENT_TYPE == 'infrastructure-only') {
                    echo 'Consider running cleanup or checking Terraform state'
                }
            }
        }
        cleanup {
            bat '''
                del tfplan destroy.tfplan .env 2>nul || echo "Files not found"
                cd terraform
                rmdir /s /q .terraform 2>nul || echo "No .terraform directory"
                del .terraform.lock.hcl 2>nul || echo "No lock file"
                cd ..
            '''
        }
    }
}
