#!/bin/bash
echo "=== Play with your OWN RISK Xp Group INC ==="
# Docker Installation Quick Fix Script
echo "=== Docker Installation Quick Fix ==="

# Kill any hanging apt processes
echo "Cleaning up hanging processes..."
sudo killall apt-get 2>/dev/null || true
sudo killall dpkg 2>/dev/null || true

# Remove lock files if they exist
echo "Removing lock files..."
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock

# Configure any unconfigured packages
echo "Configuring packages..."
sudo dpkg --configure -a

# Clean package cache
echo "Cleaning package cache..."
sudo apt-get clean
sudo apt-get autoclean

# Update package list
echo "Updating package list..."
sudo apt-get update

# Check if Docker repository exists
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "Docker repository not found. Adding it..."
    
    # Install prerequisites
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list again
    sudo apt-get update
fi

# Try installing Docker packages with verbose output
echo "Installing Docker packages..."
echo "This may take a few minutes..."

# Install packages one by one with error checking
packages=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")

for package in "${packages[@]}"; do
    echo "Installing $package..."
    if sudo apt-get install -y "$package"; then
        echo "✓ $package installed successfully"
    else
        echo "✗ Failed to install $package"
        echo "Trying alternative method..."
        
        # Try with --fix-missing flag
        sudo apt-get install -y --fix-missing "$package" || {
            echo "Failed to install $package even with --fix-missing"
            exit 1
        }
    fi
done

# Start and enable Docker service
echo "Starting Docker service..."
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Verify installation
echo "Verifying installation..."
docker --version
docker compose version

echo ""
echo "=== Installation Summary ==="
echo "Docker CE: $(docker --version 2>/dev/null || echo 'Failed to get version')"
echo "Docker Compose: $(docker compose version --short 2>/dev/null || echo 'Failed to get version')"
echo "Docker service status: $(sudo systemctl is-active docker)"
echo ""
echo "✓ Docker installation completed!"
echo "⚠ Please log out and log back in to use Docker without sudo"
echo ""
echo "Test your installation with: docker run hello-world"
echo "=== No Pain NO GAIN..Enjoy ==="

