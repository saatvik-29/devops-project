pipeline {
    agent any
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        skipDefaultCheckout()
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_VAR_region = 'us-east-1'
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
                        echo Checking for required tools...
                        
                        terraform version >nul 2>&1
                        if %errorlevel% neq 0 (
                            echo Installing Terraform...
                            powershell -Command "try { Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_windows_amd64.zip' -OutFile 'terraform.zip'; Expand-Archive -Path 'terraform.zip' -DestinationPath '.' -Force; Move-Item terraform.exe C:\\Windows\\System32\\ -Force; Remove-Item terraform.zip -Force } catch { Write-Host 'Terraform installation failed' }"
                        )

                        aws --version >nul 2>&1
                        if %errorlevel% neq 0 (
                            echo AWS CLI not found in PATH
                            echo Checking common AWS CLI locations...
                            if exist "C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe" (
                                echo Found AWS CLI, adding to PATH
                                set "PATH=C:\\Program Files\\Amazon\\AWSCLIV2;%PATH%"
                            ) else (
                                echo AWS CLI not found. Please ensure it is installed.
                            )
                        )
                        
                        echo Tool check completed
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
                                    terraform init -reconfigure
                                    terraform plan -destroy -var="environment=%AUTO_ENVIRONMENT%" -out=destroy.tfplan
                                '''
                            } else {
                                bat '''
                                    terraform init -reconfigure
                                    terraform refresh -var="environment=%AUTO_ENVIRONMENT%" || echo "Refresh failed, continuing..."
                                    terraform plan -var="environment=%AUTO_ENVIRONMENT%" -out=tfplan
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
                            bat """
                                docker-compose build --no-cache
                                echo Docker images built successfully
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        if ((env.AUTO_DEPLOYMENT_TYPE == 'application-only' || env.AUTO_DEPLOYMENT_TYPE == 'full-deployment') && env.AUTO_DESTROY != 'true') {
                            // Get instance details dynamically from Terraform or AWS
                            def instanceIp = ""
                            def instanceId = ""
                            
                            // First try to get from Terraform outputs
                            dir('terraform') {
                                try {
                                    def rawIp = bat(
                                        script: 'terraform output -raw instance_ip',
                                        returnStdout: true
                                    ).trim()
                                    
                                    def rawId = bat(
                                        script: 'terraform output -raw instance_id',
                                        returnStdout: true
                                    ).trim()
                                    
                                    // Extract just the IP and ID from the output
                                    instanceIp = rawIp.split('\n').last().trim()
                                    instanceId = rawId.split('\n').last().trim()
                                    
                                    echo "Got from Terraform - Instance: ${instanceId}, IP: ${instanceIp}"
                                } catch (Exception e) {
                                    echo "Could not get Terraform outputs: ${e.message}"
                                }
                            }
                            
                            // If Terraform outputs failed, try AWS CLI
                            if (!instanceIp || !instanceId) {
                                try {
                                    def awsInstanceId = bat(
                                        script: 'set AWS_ACCESS_KEY_ID=%TF_VAR_aws_access_key% && set AWS_SECRET_ACCESS_KEY=%TF_VAR_aws_secret_key% && aws ec2 describe-instances --filters "Name=tag:Application,Values=chess" "Name=tag:Environment,Values=%AUTO_ENVIRONMENT%" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --region %AWS_DEFAULT_REGION%',
                                        returnStdout: true
                                    ).trim()
                                    
                                    def awsInstanceIp = bat(
                                        script: 'set AWS_ACCESS_KEY_ID=%TF_VAR_aws_access_key% && set AWS_SECRET_ACCESS_KEY=%TF_VAR_aws_secret_key% && aws ec2 describe-instances --filters "Name=tag:Application,Values=chess" "Name=tag:Environment,Values=%AUTO_ENVIRONMENT%" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].PublicIpAddress" --output text --region %AWS_DEFAULT_REGION%',
                                        returnStdout: true
                                    ).trim()
                                    
                                    if (awsInstanceId && !awsInstanceId.contains("None") && awsInstanceId.startsWith("i-")) {
                                        instanceId = awsInstanceId
                                    }
                                    if (awsInstanceIp && !awsInstanceIp.contains("None") && awsInstanceIp.matches(/\d+\.\d+\.\d+\.\d+/)) {
                                        instanceIp = awsInstanceIp
                                    }
                                    
                                    echo "Got from AWS CLI - Instance: ${instanceId}, IP: ${instanceIp}"
                                } catch (Exception e) {
                                    echo "Could not get AWS instance details: ${e.message}"
                                }
                            }
                            
                            // Only proceed if we have valid instance details
                            if (!instanceIp || !instanceId) {
                                error("Could not determine instance details. Please run 'full-deployment' to create infrastructure first.")
                            }

                            env.INSTANCE_IP = instanceIp
                            env.INSTANCE_ID = instanceId

                            echo "Deploying to instance ${instanceId} at IP ${instanceIp}"

                            // Use direct variable substitution in the command
                            bat """
set AWS_ACCESS_KEY_ID=%TF_VAR_aws_access_key%
set AWS_SECRET_ACCESS_KEY=%TF_VAR_aws_secret_key%
echo Deploying to instance ${instanceId} at IP ${instanceIp}
aws ssm send-command --instance-ids "${instanceId}" --document-name "AWS-RunShellScript" --parameters "commands=['cd /home/ubuntu/Chess || (git clone https://github.com/saatvik-29/devops-project.git Chess && cd Chess)','git fetch origin','git reset --hard origin/main','sudo docker-compose down || echo No containers running','sudo docker system prune -f','sudo docker-compose build --no-cache','sudo docker-compose up -d --force-recreate','sudo docker-compose ps']" --region %AWS_DEFAULT_REGION%
echo Deployment command sent successfully to ${instanceId}
echo Frontend: http://${instanceIp}:5173
echo Backend: ws://${instanceIp}:8181
"""
                        }
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    if ((params.DEPLOYMENT_TYPE == 'application-only' || params.DEPLOYMENT_TYPE == 'full-deployment') && !params.DESTROY_INFRASTRUCTURE) {
                        def instanceIp = env.INSTANCE_IP ?: bat(
                            script: 'cd terraform && terraform output -raw instance_ip',
                            returnStdout: true
                        ).trim()
                        instanceIp = instanceIp.replaceAll(/.*?(\d+\.\d+\.\d+\.\d+).*/, '$1')
                        env.INSTANCE_IP = instanceIp

                        echo "Performing health checks on instance ${instanceIp}"

                        bat """
echo Performing health checks...

powershell -Command "try { Invoke-WebRequest -Uri 'http://${instanceIp}:5173' -TimeoutSec 10 | Out-Null; Write-Host 'Frontend is healthy' } catch { Write-Host 'Frontend check failed'; exit 1 }"

powershell -Command "for (\$i=0; \$i -lt 5; \$i++) { try { \$tcp = New-Object System.Net.Sockets.TcpClient; \$tcp.Connect('${instanceIp}', 8181); \$tcp.Close(); Write-Host 'Backend is healthy'; break } catch { Write-Host 'Waiting for backend...'; Start-Sleep 2 } }"
"""
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                def instanceIp = env.INSTANCE_IP ?: "N/A"
                
                if (!params.DESTROY_INFRASTRUCTURE && (params.DEPLOYMENT_TYPE == 'full-deployment' || params.DEPLOYMENT_TYPE == 'infrastructure-only')) {
                    try {
                        dir('terraform') {
                            def output = bat(
                                script: 'terraform output -raw instance_ip 2>nul || echo N/A',
                                returnStdout: true
                            ).trim()
                            if (output && !output.contains("N/A") && !output.contains("Warning")) {
                                instanceIp = output.replaceAll(/.*?(\d+\.\d+\.\d+\.\d+).*/, '$1')
                            }
                        }
                    } catch (Exception e) {
                        echo "Could not retrieve Terraform outputs: ${e.message}"
                    }
                }

                echo """
========================================
DEPLOYMENT SUMMARY
========================================
Environment: ${params.ENVIRONMENT ?: env.AUTO_ENVIRONMENT}
Deployment Type: ${params.DEPLOYMENT_TYPE ?: env.AUTO_DEPLOYMENT_TYPE}
Instance IP: ${instanceIp}
Frontend URL: http://${instanceIp}:5173
Backend WebSocket: ws://${instanceIp}:8181
Git Commit: ${env.GIT_COMMIT_SHORT}
========================================
"""
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
            bat 'del tfplan destroy.tfplan .env 2>nul || echo Files not found'
        }
    }
}   
