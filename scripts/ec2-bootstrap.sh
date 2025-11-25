#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrap script for an EC2 host to run a Python app
# Usage (on the EC2 instance): sudo bash ec2-bootstrap.sh /opt/demo-app

DEST=${1:-/opt/demo-app}

echo "Bootstrapping host to run app under ${DEST}"

if command -v yum >/dev/null 2>&1; then
  echo "Detected yum-based distro (Amazon Linux / RHEL / CentOS)"
  sudo yum update -y
  sudo yum install -y python3 python3-pip git
elif command -v apt-get >/dev/null 2>&1; then
  echo "Detected apt-based distro (Ubuntu/Debian)"
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-pip git
else
  echo "Unknown distro - please install python3, pip and git manually"
fi

# Create the deploy directory and set permissions
sudo mkdir -p "${DEST}"
sudo chown $(whoami):$(whoami) "${DEST}"

echo "Creating a user service example at /etc/systemd/system/demo-app.service (requires sudo to write)"
cat <<'SERVICE' | sudo tee /etc/systemd/system/demo-app.service
[Unit]
Description=Demo Python App
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/demo-app
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

echo "Reloading systemd and enabling demo-app.service"
sudo systemctl daemon-reload
sudo systemctl enable demo-app.service

echo "Bootstrap complete. Drop your artifact (artifact.tar.gz) in ${DEST} and run:"
echo "  tar -xzf artifact.tar.gz -C ${DEST}"
echo "  sudo systemctl restart demo-app.service"
