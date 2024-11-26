#!/bin/bash

# Function to fetch the latest release info
fetch_latest_release() {
    echo "Fetching the latest release information..."
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest)
    echo $LATEST_RELEASE
}

# Function to parse JSON for download URL
get_download_url() {
    echo "$1" | grep "browser_download_url" | grep "blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz" | cut -d '"' -f 4
}

# Remove previous files
rm -rf blockmesh-cli.tar.gz target

# Update and upgrade
apt update && apt upgrade -y

# Cleanup previous files
rm -rf blockmesh-cli.tar.gz target

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

# Fetch the latest release and parse the download URL
LATEST_RELEASE=$(fetch_latest_release)
DOWNLOAD_URL=$(get_download_url "$LATEST_RELEASE")

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Error: Unable to find download URL for the latest release. Exiting..."
    exit 1
fi

# Download and extract BlockMesh CLI
echo "Downloading and extracting BlockMesh CLI from $DOWNLOAD_URL..."
curl -L "$DOWNLOAD_URL" -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

# Verify extraction
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "Error: blockmesh-cli binary not found in target/release. Exiting..."
    exit 1
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
