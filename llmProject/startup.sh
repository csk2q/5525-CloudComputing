#!/bin/bash

# To see the output of this script run the following: (-e starts from the end, -f to follow)
# sudo journalctl -u google-startup-scripts.service -e -f

# Ensure a failure stops the script
set -euo pipefail

# Function to send a message to a Discord webhook
send_discord_message() {
  local webhook_url="${webhook_url}"
  local message="$*"
  echo "$message"

  if [[ -z "$webhook_url" || -z "$message" ]]; then
    :
  else
    curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"$message\"}" "$webhook_url"
  fi
}

# Log the start of the script
send_discord_message "# Startup script begain at $(date)"

# Install Ops Agent
send_discord_message "Installing Ops Agent..."

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Add Docker's official GPG key:
send_discord_message "Adding Docker's GPG key..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo apt-get install -y apt-transport-https gnupg

send_discord_message "Installing Docker dependencies..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

send_discord_message "Adding Docker repository..."
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

send_discord_message "Updating Docker package list..."
sudo apt-get update

send_discord_message "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure cloud logging for docker
sudo mkdir -p /etc/google-cloud-ops-agent
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << 'EOF'
logging:
  receivers:
    docker_logs:
      type: files
      include_paths:
        - /var/lib/docker/containers/*/*.log
  service:
    pipelines:
      docker_pipeline:
        receivers: [docker_logs]
EOF
sudo systemctl restart google-cloud-ops-agent


# Enable and start Docker service
send_discord_message "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

# Add the default user (UID 1000) to the docker group
send_discord_message "Adding DEFAULT_USER to docker group..."
DEFAULT_USER=$(getent passwd 1000 | cut -d: -f1)
send_discord_message "Adding $DEFAULT_USER to docker group..."
sudo usermod -aG docker "$DEFAULT_USER"
newgrp docker

# Authenticate Docker with Artifact Registry
send_discord_message "Authenticating Docker with Artifact Registry..."
sudo gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

# Pull and run the container
send_discord_message "Pulling ${ar_image}:latest..."
docker pull ${ar_image}:latest
send_discord_message "Running ${ar_image}:latest..."
docker run -d --restart unless-stopped -p 80:80 ${ar_image}:latest

send_discord_message "# Startup script finished at $(date)"
