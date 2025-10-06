#!/bin/bash

# Colors
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${YELLOW}========================================${NC}"
echo -e "${CYAN}        Welcome to Morzaa Tech         ${NC}"
echo -e "${YELLOW}========================================${NC}"

# Timestamped log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="docker-lab-diagnostic-$TIMESTAMP.log"
TARGET_IP="8.8.8.8"

# Ensure required tools are installed
for pkg in iputils-ping stun-client conntrack; do
  if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
    echo "📦 Installing missing package: $pkg"
    sudo apt update && sudo apt install -y "$pkg"
  fi
done

# Start logging
{
  echo "🕒 Docker Lab Diagnostic — $TIMESTAMP"
  echo "========================================"

  echo -e "\n🔧 Docker Version:"
  docker version 2>&1

  echo -e "\n📦 Docker Info:"
  docker info 2>&1

  echo -e "\n📋 All Containers (docker ps -a):"
  docker ps -a 2>&1

  echo -e "\n🖼️ Docker Images:"
  docker images 2>&1

  echo -e "\n🗄️ Docker Volumes:"
  docker volume ls 2>&1

  echo -e "\n🌐 Docker Networks:"
  docker network ls 2>&1

  echo -e "\n🔍 Docker Compose Projects:"
  docker compose ls 2>&1

  echo -e "\n📁 Compose Files in the system:"
  sudo find / -type f \( -name "docker-compose.yml" -o -name "docker-compose.*.yml" \) 2>/dev/null

  echo -e "\n🔍 Inspecting macvlan networks:"
  docker network inspect $(docker network ls --filter driver=macvlan -q) 2>/dev/null

  echo -e "\n🧭 Routing Table:"
  ip route show

  echo -e "\n📡 Default Interface:"
  DEFAULT_IF=$(ip route get "$TARGET_IP" 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
  echo "Default interface to reach $TARGET_IP: $DEFAULT_IF"

  echo -e "\n📶 Interface Details:"
  ip addr show "$DEFAULT_IF"

  echo -e "\n📈 Ping Test to $TARGET_IP:"
  ping -c 4 "$TARGET_IP"

  echo -e "\n🌍 Public IP (via STUN):"
  stun stun.l.google.com:19302

  echo -e "\n🔎 NAT Clues from conntrack:"
  sudo conntrack -L | grep -E 'src=|dst=' | head -n 20

  echo -e "\n📊 Docker Disk Usage:"
  docker system df

  echo -e "\n📈 Docker Events (last 5 min):"
  docker events --since 5m --until now
} | tee "$LOGFILE"

echo -e "\n✅ Diagnostic complete. Log saved to: $LOGFILE"
