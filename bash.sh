#!/bin/bash

# Varibles
share_name="share"
administrator_user="administrator"
dashy_conf="dashy-conf"

# Install Samba
sudo apt update
sudo apt install samba -y

# Create a Samba user called "administrator"
sudo useradd -m administrator
sudo smbpasswd -a administrator

#folder making
mkdir "$(eval echo ~$SUDO_USER)/share"
mkdir "$(eval echo ~$SUDO_USER)/nginx-proxy-manager"
mkdir "$(eval echo ~$SUDO_USER)/dashy"
mkdir "$(eval echo ~$SUDO_USER)/jackett"
mkdir "$(eval echo ~$SUDO_USER)/pingvinshare"
mkdir "$(eval echo ~$SUDO_USER)/radarr"
mkdir "$(eval echo ~$SUDO_USER)/sonarr"
mkdir "$(eval echo ~$SUDO_USER)/qbittorrent"
mkdir "$(eval echo ~$SUDO_USER)/website"

#Make file for website
echo "Hello world!" > $(eval echo ~$SUDO_USER)/website/src/index.html
echo "---
# Page meta info, like heading, footer text and nav links
pageInfo:
  title: Dashy
  description: Welcome to your new dashboard!
  navLinks:
  - title: GitHub
    path: https://github.com/Lissy93/dashy
  - title: Documentation
    path: https://dashy.to/docs

# Optional app settings and configuration
appConfig:
  theme: colorful

# Main content - An array of sections, each containing an array of items
sections:
- name: Getting Started
  icon: fas fa-rocket
  items:
  - title: Dashy Live
    description: Development a project management links for Dashy
    icon: https://i.ibb.co/qWWpD0v/astro-dab-128.png
    url: https://live.dashy.to/
    target: newtab
  - title: GitHub
    description: Source Code, Issues and Pull Requests
    url: https://github.com/lissy93/dashy
    icon: favicon
  - title: Docs
    description: Configuring & Usage Documentation
    provider: Dashy.to
    icon: far fa-book
    url: https://dashy.to/docs
  - title: Showcase
    description: See how others are using Dashy
    url: https://github.com/Lissy93/dashy/blob/master/docs/showcase.md
    icon: far fa-grin-hearts
  - title: Config Guide
    description: See full list of configuration options
    url: https://github.com/Lissy93/dashy/blob/master/docs/configuring.md
    icon: fas fa-wrench
  - title: Support
    description: Get help with Dashy, raise a bug, or get in contact
    url: https://github.com/Lissy93/dashy/blob/master/.github/SUPPORT.md
    icon: far fa-hands-helping
  " > $(eval echo ~$SUDO_USER)/dashy/config/$dashy_conf.yml

# Replace "folder_path" with the actual path of the folder you want to share
folder_path="$(eval echo ~$SUDO_USER)/share"


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

# Nginx Proxy Manager
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
      - "$(eval echo ~$SUDO_USER)/nginx-proxy-manager/data:/config"
    environment:
      - PUID=1000
      - PGID=1000

EOF

# Dashy
cat << EOF > dashy-compose.yml
version: "3.8"
services:
  dashy:
    image: lissy93/dashy
    container_name: Dashy
    ports:
      - 4000:80
    # Set any environmental variables
    environment:
      - NODE_ENV=production
      - UID=1000
      - GID=1000
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

# Jackett
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
      - "$(eval echo ~$SUDO_USER)/jackett/config:/config"
      - "$(eval echo ~$SUDO_USER)/jackett/downloads:/downloads"

EOF

# Pingvinshare
cat << EOF > pingvinshare-compose.yml
version: '3.8'
services:
  pingvin-share:
    image: stonith404/pingvin-share
    container_name: pingvin-share
    restart: unless-stopped
    ports:
      - 3000:3000
    volumes:
      - "$(eval echo ~$SUDO_USER)/pingvinshare/omdata:/opt/app/backend/data"
      - "$(eval echo ~$SUDO_USER)/pingvinshare/data/images:/opt/app/frontend/public/img"

EOF

# Radarr
cat << EOF > radarr-compose.yml
version: "2.1"
services:
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - "$(eval echo ~$SUDO_USER)/radarr/data:/config"
      - "$(eval echo ~$SUDO_USER)/radarr/movies:/movies"
      - "$(eval echo ~$SUDO_USER)/radarr/downloadclient-downloads:/downloads"
    ports:
      - 7878:7878
    restart: unless-stopped
EOF

# Sonarr
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
      - "$(eval echo ~$SUDO_USER)/sonarr/data:/config"
      - "$(eval echo ~$SUDO_USER)/sonarr/tvseries:/tv"
      - "$(eval echo ~$SUDO_USER)/sonarr/downloadclient-downloads:/downloads"
    ports:
      - 8989:8989
    restart: unless-stopped

EOF

# Qbittorrent
cat << EOF > qbittorrent-compose.yml
version: '3'
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000   # Set your user ID
      - PGID=1000   # Set your group ID
      - TZ=Europe/Stockholm
    volumes:
      - "$(eval echo ~$SUDO_USER)/qbittorrent/config:/config"
      - "$(eval echo ~$SUDO_USER)/qbittorrent/downloads:/downloads"
    ports:
      - 8080:8080
    restart: unless-stopped

EOF

# Website
cat << EOF > website-compose.yml
version: "3"

services:
    client:
        image: nginx
        container_name: nginx-website
        ports:
            - 8000:80
        volumes:
            - "$(eval echo ~$SUDO_USER)/website/src:/usr/share/nginx/html"
EOF

# Docker compose start
docker-compose -f nginx-compose.yml up -d 
docker-compose -f dashy-compose.yml up -d 
docker-compose -f jackett-compose.yml up -d 
docker-compose -f pingvinshare-compose.yml up -d 
docker-compose -f radarr-compose.yml up -d 
docker-compose -f sonarr-compose.yml up -d 
docker-compose -f qbittorrent-compose.yml up -d 
docker-compose -f website-compose.yml up -d

# Setting up folder access
docker exec -i -t radarr chown abc movies
docker exec -i -t radarr chown abc downloads
docker exec -i -t sonarr chown abc tv
docker exec -i -t sonarr chown abc downloads


#Watchtower
docker run -d --name watchtower --restart=unless-stopped -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower

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

# Add user 'jellyfin' to usergroup
usermod -aG $(id -gn $SUDO_USER) jellyfin

# Give ownership of the Jellyfin data directory to 'jellyfin' user
chown -R jellyfin:jellyfin /var/lib/jellyfin

# Start Jellyfin service
systemctl start jellyfin

# Enable Jellyfin service to start on boot
systemctl enable jellyfin

# Print the URL to access Jellyfin
echo "Jellyfin is installed and running. You can access it by visiting: http://localhost:8096/"


