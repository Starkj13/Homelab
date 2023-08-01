#!/bin/bash

# Install Samba
sudo apt update
sudo apt install samba -y

# Create a Samba user called "administrator"
sudo useradd -m administrator
sudo smbpasswd -a administrator

# Replace "folder_path" with the actual path of the folder you want to share
folder_path="/home/server/Shared"

# Replace "share_name" with the desired name for the Samba share
share_name="Share"

# Replace "administrator_user" with the name of the administrator user
administrator_user="administrator"

# Add a new share configuration to the Samba configuration file
echo "[$share_name]" | sudo tee -a /etc/samba/smb.conf
echo "   path = $folder_path" | sudo tee -a /etc/samba/smb.conf
echo "   writable = yes" | sudo tee -a /etc/samba/smb.conf
echo "   guest ok = no" | sudo tee -a /etc/samba/smb.conf
echo "   read only = no" | sudo tee -a /etc/samba/smb.conf
echo "   create mask = 0777" | sudo tee -a /etc/samba/smb.conf
echo "   directory mask = 0777" | sudo tee -a /etc/samba/smb.conf
echo "   valid users = $administrator_user" | sudo tee -a /etc/samba/smb.conf

# Restart the Samba service to apply changes
sudo service smbd restart

# Install Docker and Docker Compose
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker administrator
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create a directory for the Nginx Proxy Manager data
sudo mkdir -p /opt/nginx-proxy-manager/data
sudo chown 1000:1000 /opt/nginx-proxy-manager/data

# Create the Docker Compose file for Nginx Proxy Manager
cat << EOF > docker-compose.yml
version: "3"

services:
  nginx-proxy-manager:
    image: jlesage/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - /opt/nginx-proxy-manager/data:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=your_timezone_here  # Replace with your timezone, e.g., "America/New_York"

EOF

# Create the Docker Compose file for Dashy
cat << EOF > dashy-compose.yml
version: "3"

services:
  dashy:
    image: tiangolo/dashy:latest
    container_name: dashy
    ports:
      - "8080:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

EOF

echo "Samba, Docker, Docker Compose, Nginx Proxy Manager, and Dashy Docker Compose files have been created."
# Update package list
apt update

# Install prerequisites
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Jellyfin repository key
wget -O - https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add -

# Add Jellyfin repository to sources list
echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/ubuntu $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/jellyfin.list

# Update package list again with the new repository
apt update

# Install Jellyfin
apt install -y jellyfin

# Add a user 'jellyfin' to control the service
useradd -r -s /bin/nologin jellyfin

# Give ownership of the Jellyfin data directory to 'jellyfin' user
chown -R jellyfin:jellyfin /var/lib/jellyfin

# Start Jellyfin service
systemctl start jellyfin

# Enable Jellyfin service to start on boot
systemctl enable jellyfin

# Print the URL to access Jellyfin
echo "Jellyfin is installed and running. You can access it by visiting: http://localhost:8096/"
