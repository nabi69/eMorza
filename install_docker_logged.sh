
#!/bin/bash
# This file will install Docker engineen.
# Define the log file name
LOG_FILE="docker_install.log"

# Clear the log file or create a new one
echo "Starting Docker installation script on $(date)" > "$LOG_FILE"
echo "--- All output is being logged to $LOG_FILE ---" | tee -a "$LOG_FILE"

# Group all commands and pipe their output to tee
{
    # Exit immediately if a command exits with a non-zero status.
    set -e

    # Update apt package index and install prerequisites
    echo "--- Step 1: Updating apt package index and installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker’s official GPG key
    echo "--- Step 2: Adding Docker's official GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add Docker repo
    echo "--- Step 3: Adding Docker repository to Apt sources..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    echo "--- Step 4: Installing Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker service
    echo "--- Step 5: Enabling and starting Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add the current user to the 'docker' group to run docker commands without sudo
    echo "--- Step 6: Adding current user to the 'docker' group..."
    sudo usermod -aG docker "$USER"

    echo "--- Docker installation completed successfully! ---"
} 2>&1 | tee -a "$LOG_FILE"

echo "Log file created successfully: $LOG_FILE"
