#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Git
apt-get install -y git

# Install additional tools
apt-get install -y htop curl wget net-tools

# Create application directory
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Clone the repository
git clone ${git_repo} .
git checkout ${branch}

# Set proper permissions
chown -R ubuntu:ubuntu /home/ubuntu/app

# Create systemd service for auto-start
cat > /etc/systemd/system/chess-app.service << EOF
[Unit]
Description=Chess Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/app
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable chess-app.service

# Start the application
cd /home/ubuntu/app
sudo -u ubuntu docker-compose up -d

# Create health check script
cat > /home/ubuntu/health_check.sh << 'EOF'
#!/bin/bash
# Health check script for Chess application

FRONTEND_URL="http://localhost:5173"
BACKEND_PORT="8181"

# Check frontend
if curl -f -s "$FRONTEND_URL" > /dev/null; then
    echo "Frontend is healthy"
    FRONTEND_STATUS="OK"
else
    echo "Frontend is down"
    FRONTEND_STATUS="FAIL"
fi

# Check backend
if nc -z localhost $BACKEND_PORT; then
    echo "Backend is healthy"
    BACKEND_STATUS="OK"
else
    echo "Backend is down"
    BACKEND_STATUS="FAIL"
fi

# Overall status
if [ "$FRONTEND_STATUS" = "OK" ] && [ "$BACKEND_STATUS" = "OK" ]; then
    echo "Application is healthy"
    exit 0
else
    echo "Application is unhealthy"
    exit 1
fi
EOF

chmod +x /home/ubuntu/health_check.sh

# Create log rotation for Docker
cat > /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Set up monitoring script
cat > /home/ubuntu/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script

while true; do
    echo "$(date): Checking application health..."
    /home/ubuntu/health_check.sh
    if [ $? -ne 0 ]; then
        echo "$(date): Application unhealthy, restarting..."
        cd /home/ubuntu/app
        sudo -u ubuntu docker-compose restart
    fi
    sleep 60
done
EOF

chmod +x /home/ubuntu/monitor.sh

# Start monitoring in background
nohup /home/ubuntu/monitor.sh > /home/ubuntu/monitor.log 2>&1 &

# Log completion
echo "$(date): User data script completed" >> /var/log/user-data.log
