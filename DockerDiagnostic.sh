#!/bin/bash
#==============================================================================
# Enhanced Docker & System Diagnostics Script
# Author: Morzaa Tech
# Description: Comprehensive diagnostic tool for Docker environments
#==============================================================================

# Colors and formatting
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="docker-lab-diagnostic-$TIMESTAMP.log"
LOG_DIR="./diagnostic-logs"
TARGET_IP="8.8.8.8"
DNS_SERVERS=("8.8.8.8" "1.1.1.1")
RETENTION_DAYS=7

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/$LOGFILE"

#==============================================================================
# Helper Functions
#==============================================================================

print_banner() {
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Welcome to Morzaa Tech                      ║${NC}"
    echo -e "${CYAN}║     Enhanced Docker & System Diagnostics v2.0         ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}📅 Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
    echo -e "${GREEN}💾 Log file: $LOGFILE${NC}\n"
}

print_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_subsection() {
    echo -e "\n${MAGENTA}▶ $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

install_missing_packages() {
    local packages=("iputils-ping" "net-tools" "curl" "wget" "jq" "htop" "iotop" "iftop" "dnsutils" "traceroute" "tcpdump" "strace" "sysstat")
    local missing_packages=()
    
    print_section "📦 Checking Required Packages"
    
    for pkg in "${packages[@]}"; do
        local cmd="${pkg%%-*}"
        if ! check_command "$cmd"; then
            missing_packages+=("$pkg")
            echo -e "${YELLOW}⚠️  Missing: $pkg${NC}"
        else
            echo -e "${GREEN}✓ Found: $pkg${NC}"
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo -e "\n${CYAN}Upgrade and Installing missing packages...${NC}"
        sudo apt update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
        sudo apt install -y "${missing_packages[@]}"
    else
        echo -e "\n${GREEN}✓ All required packages are installed${NC}"
    fi
}

#==============================================================================
# System Information Functions
#==============================================================================

system_overview() {
    print_section "🖥️  System Overview"
    
    print_subsection "Hostname & Kernel"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    
    print_subsection "OS Information"
    if [ -f /etc/os-release ]; then
        cat /etc/os-release
    else
        lsb_release -a 2>/dev/null
    fi
    
    print_subsection "System Uptime & Load"
    uptime
    
    print_subsection "Last Reboot"
    who -b
}

hardware_info() {
    print_section "🔧 Hardware Information"
    
    print_subsection "CPU Information"
    lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core|Socket"
    
    print_subsection "Memory Information"
    free -h
    echo ""
    cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree"
    
    print_subsection "Disk Information"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
    echo ""
    df -hT | grep -v tmpfs
    
    print_subsection "I/O Statistics (5 samples)"
    iostat -x 1 5 2>/dev/null || echo "iostat not available"
}

resource_usage() {
    print_section "📊 Resource Usage"
    
    print_subsection "CPU & Memory Usage"
    top -b -n 1 | head -n 20
    
    print_subsection "Memory Details"
    vmstat 1 5
    
    print_subsection "Top 10 Processes by CPU"
    ps aux --sort=-%cpu | head -n 11
    
    print_subsection "Top 10 Processes by Memory"
    ps aux --sort=-%mem | head -n 11
    
    print_subsection "Disk I/O (if iotop available)"
    if check_command iotop; then
        sudo iotop -b -n 3 -o -a 2>/dev/null || echo "iotop requires sudo"
    else
        echo "iotop not installed"
    fi
}

system_services() {
    print_section "⚙️  System Services"
    
    print_subsection "Active Services"
    systemctl list-units --type=service --state=running | head -n 25
    
    print_subsection "Failed Services"
    systemctl --failed
    
    print_subsection "Services Enabled at Boot"
    systemctl list-unit-files --type=service --state=enabled | head -n 20
}

security_audit() {
    print_section "🔒 Security Audit"
    
    print_subsection "Logged-in Users"
    who
    w
    
    print_subsection "Recent Login Attempts"
    last -n 10
    
    print_subsection "Failed Login Attempts"
    sudo lastb -n 10 2>/dev/null || echo "No failed login records"
    
    print_subsection "Firewall Status (UFW)"
    sudo ufw status verbose 2>/dev/null || echo "UFW not available"
    
    print_subsection "IPTables Rules"
    sudo iptables -L -n -v --line-numbers 2>/dev/null | head -n 50
    
    print_subsection "Open Ports"
    sudo ss -tuln | grep LISTEN
    
    print_subsection "Suspicious SUID/SGID Files (sample)"
    find / -perm /6000 -type f 2>/dev/null | head -n 20
}

#==============================================================================
# Network Diagnostics
#==============================================================================

network_diagnostics() {
    print_section "🌐 Network Diagnostics"
    
    print_subsection "Network Interfaces"
    ip -brief address
    echo ""
    ip -details link show
    
    print_subsection "Routing Table"
    ip route show
    echo ""
    ip route show table all
    
    print_subsection "Default Gateway & Interface"
    DEFAULT_IF=$(ip route get "$TARGET_IP" 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
    DEFAULT_GW=$(ip route | grep default | awk '{print $3}')
    echo "Default interface to reach $TARGET_IP: $DEFAULT_IF"
    echo "Default gateway: $DEFAULT_GW"
    
    print_subsection "Interface Statistics"
    if [ -n "$DEFAULT_IF" ]; then
        ip -s link show "$DEFAULT_IF"
    fi
    
    print_subsection "ARP Table"
    ip neigh show
    
    print_subsection "Connection Tracking"
    sudo conntrack -L 2>/dev/null | head -n 30 || echo "conntrack not available"
    
    print_subsection "Active Network Connections"
    sudo ss -tunap | head -n 50
    
    print_subsection "Network Statistics"
    netstat -s | head -n 50
}

dns_tests() {
    print_section "🔍 DNS & Connectivity Tests"
    
    for dns in "${DNS_SERVERS[@]}"; do
        print_subsection "Testing DNS: $dns"
        ping -c 3 -W 2 "$dns"
        echo ""
    done
    
    print_subsection "DNS Resolution Test"
    for domain in "google.com" "github.com" "docker.io"; do
        echo "Resolving $domain:"
        nslookup "$domain" 2>&1 | head -n 10
        echo ""
    done
    
    print_subsection "Public IP Detection"
    echo "Via ipify.org:"
    curl -s --max-time 5 https://api.ipify.org || echo "Failed to detect"
    echo ""
    echo "Via ipinfo.io:"
    curl -s --max-time 5 https://ipinfo.io/ip || echo "Failed to detect"
    
    print_subsection "Traceroute to $TARGET_IP"
    traceroute -n -w 2 -m 15 "$TARGET_IP" 2>&1 | head -n 20
}

#==============================================================================
# Docker Diagnostics
#==============================================================================

docker_overview() {
    print_section "🐳 Docker Overview"
    
    print_subsection "Docker Version"
    docker version 2>&1
    
    print_subsection "Docker Info"
    docker info 2>&1
    
    print_subsection "Docker System Status"
    docker system df -v
    
    print_subsection "Docker Root Directory"
    docker info 2>&1 | grep "Docker Root Dir"
    sudo du -sh /var/lib/docker 2>/dev/null || echo "Cannot access Docker root"
}

docker_containers() {
    print_section "📦 Docker Containers"
    
    print_subsection "All Containers"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    
    print_subsection "Container Resource Usage"
    docker stats --no-stream
    
    print_subsection "Container Logs (last 50 lines per container)"
    for container in $(docker ps -q); do
        container_name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
        echo -e "\n${CYAN}Container: $container_name${NC}"
        docker logs --tail 50 "$container" 2>&1
    done
    
    print_subsection "Stopped/Failed Containers"
    docker ps -a --filter "status=exited" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}"
}

docker_networks() {
    print_section "🌐 Docker Networks"
    
    print_subsection "All Networks"
    docker network ls
    
    print_subsection "Network Inspection (detailed)"
    for network in $(docker network ls -q); do
        network_name=$(docker network inspect --format='{{.Name}}' "$network")
        echo -e "\n${CYAN}═══ Network: $network_name ═══${NC}"
        docker network inspect "$network" | jq '.' 2>/dev/null || docker network inspect "$network"
    done
    
    print_subsection "Macvlan Networks Detail"
    docker network ls --filter driver=macvlan --format "{{.ID}}" | while read -r net; do
        echo -e "\n${CYAN}Macvlan Network Details:${NC}"
        docker network inspect "$net"
    done
    
    print_subsection "Docker Bridge Configuration"
    sudo brctl show 2>/dev/null || echo "bridge-utils not installed"
}

docker_images_volumes() {
    print_section "🖼️  Docker Images & Volumes"
    
    print_subsection "Images"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}"
    
    print_subsection "Dangling Images"
    docker images -f "dangling=true"
    
    print_subsection "Volumes"
    docker volume ls
    
    print_subsection "Volume Details"
    docker volume ls -q | while read -r vol; do
        echo -e "\n${CYAN}Volume: $vol${NC}"
        docker volume inspect "$vol"
    done
}

docker_compose() {
    print_section "📋 Docker Compose"
    
    print_subsection "Active Compose Projects"
    docker compose ls 2>&1
    
    print_subsection "Compose Files in System"
    sudo find /home /root /opt -type f \( -name "docker-compose.yml" -o -name "docker-compose.*.yml" \) 2>/dev/null
    
    print_subsection "Compose Project Details"
    for compose_file in $(sudo find /home /root /opt -name "docker-compose.yml" 2>/dev/null | head -n 5); do
        echo -e "\n${CYAN}File: $compose_file${NC}"
        head -n 30 "$compose_file"
        echo "..."
    done
}

docker_troubleshooting() {
    print_section "🔧 Docker Troubleshooting"
    
    print_subsection "Recent Docker Events (last 10 min)"
    docker events --since 10m --until now
    
    print_subsection "Docker Port Bindings"
    sudo lsof -i -nP | grep -i docker | head -n 30
    
    print_subsection "Docker Daemon Logs (last 100 lines)"
    sudo journalctl -u docker.service -n 100 --no-pager
    
    print_subsection "Container Health Status"
    docker ps --filter "health=unhealthy"
    
    print_subsection "Docker Daemon Configuration"
    cat /etc/docker/daemon.json 2>/dev/null || echo "No daemon.json found"
}

#==============================================================================
# Cleanup & Maintenance
#==============================================================================

cleanup_operations() {
    print_section "🧹 Cleanup Operations"
    
    print_subsection "Pruning Unused Docker Resources"
    echo "Removing stopped containers..."
    docker container prune -f
    
    echo "Removing dangling images..."
    docker image prune -f
    
    echo "Removing unused volumes..."
    docker volume prune -f
    
    echo "Removing unused networks..."
    docker network prune -f
    
    print_subsection "Old Diagnostic Logs Cleanup"
    echo "Removing logs older than $RETENTION_DAYS days from $LOG_DIR..."
    find "$LOG_DIR" -name "docker-lab-diagnostic-*.log" -type f -mtime +$RETENTION_DAYS -exec rm -v {} \;
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    print_banner
    
    # Install missing packages
    install_missing_packages
    
    # Start logging
    {
        print_section "🚀 Starting Comprehensive Diagnostics"
        echo "Start time: $(date)"
        
        # System diagnostics
        system_overview
        hardware_info
        resource_usage
        system_services
        security_audit
        
        # Network diagnostics
        network_diagnostics
        dns_tests
        
        # Docker diagnostics
        docker_overview
        docker_containers
        docker_networks
        docker_images_volumes
        docker_compose
        docker_troubleshooting
        
        # Cleanup
        cleanup_operations
        
        print_section "✅ Diagnostic Complete"
        echo "End time: $(date)"
        echo "Total execution time: $SECONDS seconds"
        
    } 2>&1 | tee "$LOGFILE"
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Diagnostic complete!${NC}"
    echo -e "${CYAN}📄 Full log saved to: ${BOLD}$LOGFILE${NC}"
    echo -e "${CYAN}📊 Log size: $(du -h "$LOGFILE" | cut -f1)${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main
