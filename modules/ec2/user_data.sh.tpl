#!/bin/bash
# -----------------------------------------------------------------------------
# EC2 User Data Script
# This script runs on first boot to configure the instance
# -----------------------------------------------------------------------------

set -e

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script..."
echo "Environment: ${environment}"
echo "App Port: ${app_port}"

# Update system packages
dnf update -y

# Install useful utilities
dnf install -y \
    htop \
    jq \
    curl \
    wget

# Install and start SSM agent (usually pre-installed on Amazon Linux 2023)
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install CloudWatch agent for metrics and logs
dnf install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ec2/${environment}/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/ec2/${environment}/user-data",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"]
      },
      "mem": {
        "measurement": ["mem_used_percent"]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create a simple health check endpoint
# In production, this would be replaced by your actual application
cat > /usr/local/bin/health-server.py <<EOF
#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"status": "healthy", "environment": "${environment}"}
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<h1>Hello from EC2!</h1><p>Environment: ${environment}</p>')

    def log_message(self, format, *args):
        return  # Suppress logging

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', ${app_port}), HealthHandler)
    print(f'Starting server on port ${app_port}')
    server.serve_forever()
EOF

chmod +x /usr/local/bin/health-server.py

# Create systemd service for the health server
cat > /etc/systemd/system/health-server.service <<EOF
[Unit]
Description=Health Check Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/health-server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start the health server
systemctl daemon-reload
systemctl enable health-server
systemctl start health-server

echo "User data script completed successfully!"
