#!/bin/bash

# Install Samba
sudo apt update
sudo apt install samba -y

# Create a Samba user called "administrator"
sudo useradd -m administrator
sudo smbpasswd -a administrator

# Replace "folder_path" with the actual path of the folder you want to share
folder_path="/path/to/your/folder"

# Replace "share_name" with the desired name for the Samba share
share_name="YourShareName"

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
cat << EOF > nginx-compose.yml
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
      - TZ=Europe/Stockholm  # Replace with your timezone, e.g., "America/New_York"

EOF
#Docker run Nginx
docker-compose -f nginx-compose.yml up -d

# Create the Docker Compose file for Dashy
cat << EOF > dashy-compose.yml
version: "3.8"
services:
  dashy:
    # To build from source, replace 'image: lissy93/dashy' with 'build: .'
    # build: .
    image: lissy93/dashy
    container_name: Dashy
    # Pass in your config file below, by specifying the path on your host machine
    # volumes:
      # - /root/my-config.yml:/app/public/conf.yml
    ports:
      - 4000:80
    # Set any environmental variables
    environment:
      - NODE_ENV=production
    # Specify your user ID and group ID. You can find this by running `id -u` and `id -g`
    #  - UID=1000
    #  - GID=1000
    # Specify restart policy
    restart: unless-stopped
    # Configure healthchecks
    healthcheck:
      test: ['CMD', 'node', '/app/services/healthcheck']
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s

EOF

docker-compose -f dashy-compose.yml up -d

cat << EOF > jackett-compose.yml
version: "3.8"

services:
  jackett:
    image: linuxserver/jackett
    container_name: jackett
    restart: unless-stopped
    ports:
      - "9117:9117"
    volumes:
      - /path/to/config:/config
      - /path/to/downloads:/downloads

EOF

docker-compose -f jackett-compose.yml up -d

cat << EOF > pingvinshare-compose.yml
version: '3.8'
services:
  pingvin-share:
    image: stonith404/pingvin-share
    restart: unless-stopped
    ports:
      - 3000:3000
    volumes:
      - "./data:/opt/app/backend/data"
      - "./data/images:/opt/app/frontend/public/img"

EOF

docker-compose -f pingvinshare-compose.yml up -d

cat << EOF > radarr-compose.yml
version: "2.1"
services:
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /path/to/data:/config
      - /path/to/movies:/movies #optional
      - /path/to/downloadclient-downloads:/downloads #optional
    ports:
      - 7878:7878
    restart: unless-stopped
EOF

docker-compose -f radarr-compose.yml up -d

cat << EOF > sonarr-compose.yml
version: "2.1"
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /path/to/data:/config
      - /path/to/tvseries:/tv #optional
      - /path/to/downloadclient-downloads:/downloads #optional
    ports:
      - 8989:8989
    restart: unless-stopped

EOF

docker-compose -f sonarr-compose.yml up -d

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
