#!/bin/bash

# Clean up old files
rm -rf blockmesh-cli.tar.gz target

# Update and upgrade
apt update && apt upgrade -y

# Install jq if not installed
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    apt-get install -y jq
else
    echo "jq is already installed, skipping..."
fi

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker is already installed, skipping..."
fi

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create target directory for extraction
mkdir -p target/release

# Fetch the latest release version from GitHub API
echo "Fetching the latest release version..."
release_info=$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest)
version=$(echo "$release_info" | jq -r '.tag_name')

if [[ -z "$version" ]]; then
    echo "Error: Unable to fetch the latest version. Exiting..."
    exit 1
fi

echo "Latest version: $version"

# Download and extract BlockMesh CLI
echo "Downloading and extracting BlockMesh CLI version $version..."
download_url="https://github.com/block-mesh/block-mesh-monorepo/releases/download/$version/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
curl -L "$download_url" -o blockmesh-cli.tar.gz

# Verify the downloaded file type
file blockmesh-cli.tar.gz | grep -q "gzip compressed data" || { echo "Downloaded file is not a valid gzip archive. Exiting..."; exit 1; }

# Extract the file
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

# Verify extraction
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "Error: blockmesh-cli binary not found in target/release. Exiting..."
    exit 1
fi

# Check if the container is running and stop it
if docker ps -q -f name=blockmesh-cli-container > /dev/null; then
    echo "Stopping running container blockmesh-cli-container..."
    docker stop blockmesh-cli-container
fi

# Prompt for email and password
read -p "Enter your BlockMesh email: " email
read -s -p "Enter your BlockMesh password: " password
echo

# Run the Docker container with the BlockMesh CLI
echo "Creating a Docker container for the BlockMesh CLI..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
