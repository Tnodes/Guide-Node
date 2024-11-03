#!/bin/bash

# Update and upgrade the system
sudo apt update -y && sudo apt upgrade -y

# Remove any existing Docker packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 
done

# Install certificates and download the Docker GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update again and install Docker
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Set execute permissions for docker-compose if necessary
sudo chmod +x /usr/local/bin/docker-compose

# Clone the SixGPT Miner repository
git clone https://github.com/sixgpt/miner.git
cd miner

# Prompt the user for the private key and set network to moksha
read -p "Enter your private key 0x address: " VANA_PRIVATE_KEY
export VANA_PRIVATE_KEY
export VANA_NETWORK="moksha"

# Run SixGPT Miner using Docker Compose
docker compose up -d

# Verify the container status
docker ps
