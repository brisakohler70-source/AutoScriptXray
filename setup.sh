#!/bin/bash
# AutoScriptXray Installation Script
# Edition : Stable Edition 2.0 (Refactored)
# Author  : givps (refactored for better readability)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

set -euo pipefail

# Source common library functions for consistent UI and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/dev/lib/common.sh" ]]; then
    # shellcheck source=dev/lib/common.sh
    source "$SCRIPT_DIR/dev/lib/common.sh"
else
    # Fallback color definitions if library is not available
    readonly BGreen='\e[1;32m'
    readonly BRed='\e[1;31m'
    readonly BBlue='\e[1;34m'
    readonly BYellow='\e[1;33m'
    readonly NC='\e[0m'
    show_info() { echo -e "\e[1;36m[INFO]\e[0m $1"; }
    show_error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }
    show_success() { echo -e "\e[1;32m[SUCCESS]\e[0m $1"; }
fi

# =========================================
# INSTALLATION CONFIGURATION
# =========================================

# Installation timer for performance tracking
readonly START_TIME
START_TIME=$(date +%s)
# =========================================
# UTILITY FUNCTIONS
# =========================================

# Function to display installation time in human readable format
display_installation_time() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(((seconds / 60) % 60))
    local secs=$((seconds % 60))
    echo "Installation time: ${hours} hours ${minutes} minutes ${secs} seconds"
}

# Function to validate system requirements
validate_system_requirements() {
    show_info "Validating system requirements..."
    
    # Check if running as root
    if [[ "${EUID}" -ne 0 ]]; then
        show_error "This script must be run as root"
        echo "Please run: sudo bash $0"
        exit 1
    fi
    
    # Check virtualization type
    local virt_type
    virt_type=$(systemd-detect-virt 2>/dev/null || echo "unknown")
    if [[ "$virt_type" == "openvz" ]]; then
        show_error "OpenVZ virtualization is not supported"
        echo "This script requires KVM or VMWare virtualization"
        exit 1
    fi
    
    show_success "System requirements validated"
}

# Function to configure basic system settings
configure_system_basics() {
    show_info "Configuring basic system settings..."
    
    cd /root || exit 1
    rm -rf setup.sh 2>/dev/null || true
    
    # Fix hostname resolution
    local localip
    localip=$(hostname -I | cut -d' ' -f1)
    local hostname_entry
    hostname_entry=$(hostname)
    
    if ! grep -q "$(hostname)" /etc/hosts; then
        echo "$localip $hostname_entry" >> /etc/hosts
        show_info "Added hostname to /etc/hosts"
    fi
    
    # Set timezone to Jakarta
    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    
    # Disable IPv6 to avoid potential issues
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
    
    show_success "Basic system configuration completed"
}
# Function to setup required directories
setup_directories() {
    show_info "Setting up required directories..."
    
    # Create necessary directories
    local directories=(
        "/etc/xray"
        "/etc/v2ray"
        "/var/lib"
        "/home/vps/public_html"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
    done
    
    # Create domain configuration files
    local domain_files=(
        "/etc/xray/domain"
        "/etc/v2ray/domain"
        "/etc/xray/scdomain"
        "/etc/v2ray/scdomain"
    )
    
    for file in "${domain_files[@]}"; do
        touch "$file"
    done
    
    show_success "Directory structure created"
}

# Function to check and install kernel headers
install_kernel_headers() {
    show_info "Checking kernel headers installation..."
    
    local kernel_version
    kernel_version=$(uname -r)
    local required_package="linux-headers-$kernel_version"
    
    if ! dpkg -s "$required_package" >/dev/null 2>&1; then
        echo -e "[ ${BRed}WARNING${NC} ] Kernel headers not found. Installing..."
        echo "Installing: $required_package"
        
        if ! apt-get --yes install "$required_package"; then
            show_error "Failed to install kernel headers"
            echo ""
            echo -e "[ ${BBlue}SOLUTION${NC} ] Please run the following commands:"
            echo -e "[ ${BBlue}SOLUTION${NC} ] apt update && apt upgrade -y && reboot"
            echo -e "[ ${BBlue}SOLUTION${NC} ] Then run this script again"
            echo ""
            read -rp "Press Enter to acknowledge..."
            exit 1
        fi
    fi
    
    # Verify installation
    if ! dpkg -s "$required_package" >/dev/null 2>&1; then
        show_error "Kernel headers installation verification failed"
        exit 1
    fi
    
    show_success "Kernel headers verified"
}

# Function to install essential packages
install_essential_packages() {
    show_info "Installing essential packages..."
    
    local packages=(
        "git"
        "curl"
        "python3"
        "wget"
        "unzip"
        "zip"
    )
    
    # Update package list
    apt update >/dev/null 2>&1
    
    # Install packages
    for package in "${packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            show_info "Installing $package..."
            apt install -y "$package" >/dev/null 2>&1
        fi
    done
    
    show_success "Essential packages installed"
}

# Function to configure domain settings
configure_domain() {
    show_info "Setting up domain configuration..."
    
    clear
    echo -e "$BBlue                     DOMAIN SETUP                     $NC"
    echo -e "$BYellow----------------------------------------------------------$NC"
    echo -e "$BGreen [1] Use Random Domain (Automatic)$NC"
    echo -e "$BGreen [2] Use Custom Domain (Manual)$NC"
    echo -e "$BYellow----------------------------------------------------------$NC"
    
    local choice
    while true; do
        read -rp "Choose option [1-2]: " choice
        case $choice in
            1)
                show_info "Setting up random domain..."
                if ! wget -q https://raw.githubusercontent.com/givps/AutoScriptXray/master/ssh/cf; then
                    show_error "Failed to download domain setup script"
                    exit 1
                fi
                chmod +x cf && ./cf
                break
                ;;
            2)
                echo ""
                read -rp "Enter your domain name: " custom_domain
                if [[ -z "$custom_domain" ]]; then
                    show_error "Domain cannot be empty"
                    continue
                fi
                
                # Validate domain format (basic validation)
                if [[ ! "$custom_domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
                    show_error "Invalid domain format"
                    continue
                fi
                
                # Configure custom domain
                echo "IP=$custom_domain" > /var/lib/ipvps.conf
                echo "$custom_domain" > /root/scdomain
                echo "$custom_domain" > /etc/xray/scdomain
                echo "$custom_domain" > /etc/xray/domain
                echo "$custom_domain" > /etc/v2ray/domain
                echo "$custom_domain" > /root/domain
                
                show_success "Custom domain configured: $custom_domain"
                break
                ;;
            *)
                show_error "Invalid option. Please choose 1 or 2"
                ;;
        esac
    done
    
    sleep 1
}

# Function to install SSH/WebSocket services
install_ssh_services() {
    show_info "Installing SSH & WebSocket services..."
    
    echo -e "${BYellow}===================================================${NC}"
    echo -e "${BGreen}           Installing SSH WebSocket              ${NC}"
    echo -e "${BYellow}===================================================${NC}"
    
    if ! wget -q https://raw.githubusercontent.com/givps/AutoScriptXray/master/ssh/ssh-vpn.sh; then
        show_error "Failed to download SSH installation script"
        exit 1
    fi
    
    chmod +x ssh-vpn.sh
    if ! ./ssh-vpn.sh; then
        show_error "SSH installation failed"
        exit 1
    fi
    
    show_success "SSH & WebSocket services installed"
    sleep 1
}

# Function to install Xray services
install_xray_services() {
    show_info "Installing Xray services..."
    
    echo -e "${BYellow}===================================================${NC}"
    echo -e "${BGreen}              Installing XRAY                    ${NC}"
    echo -e "${BYellow}===================================================${NC}"
    
    # Install main Xray
    if ! wget -q https://raw.githubusercontent.com/givps/AutoScriptXray/master/xray/ins-xray.sh; then
        show_error "Failed to download Xray installation script"
        exit 1
    fi
    
    chmod +x ins-xray.sh
    if ! ./ins-xray.sh; then
        show_error "Xray installation failed"
        exit 1
    fi
    
    # Install SSH WebSocket support
    if ! wget -q https://raw.githubusercontent.com/givps/AutoScriptXray/master/sshws/insshws.sh; then
        show_error "Failed to download SSH WebSocket script"
        exit 1
    fi
    
    chmod +x insshws.sh
    if ! ./insshws.sh; then
        show_error "SSH WebSocket installation failed"
        exit 1
    fi
    
    show_success "Xray services installed"
    sleep 1
}
# Function to configure user profile and menu system
configure_user_profile() {
    show_info "Configuring user profile and menu system..."
    
    # Create .profile for automatic menu loading
    cat > /root/.profile << 'EOF'
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n || true
clear
menu
EOF
    
    chmod 644 /root/.profile
    show_success "User profile configured"
}

# Function to setup logging system
setup_logging_system() {
    show_info "Setting up logging system..."
    
    # Remove old log files
    rm -f /root/log-install.txt /etc/afak.conf 2>/dev/null || true
    
    # Create log files for different services
    local log_files=(
        "/etc/log-create-ssh.log:Log SSH Account"
        "/etc/log-create-vmess.log:Log Vmess Account"
        "/etc/log-create-vless.log:Log Vless Account"
        "/etc/log-create-trojan.log:Log Trojan Account"
        "/etc/log-create-shadowsocks.log:Log Shadowsocks Account"
    )
    
    for log_entry in "${log_files[@]}"; do
        local file="${log_entry%:*}"
        local header="${log_entry#*:}"
        if [[ ! -f "$file" ]]; then
            echo "$header" > "$file"
        fi
    done
    
    show_success "Logging system configured"
}

# Function to finalize installation
finalize_installation() {
    show_info "Finalizing installation..."
    
    # Clear command history for security
    history -c
    
    # Get server version and save to file
    local server_version
    server_version=$(curl -sS https://raw.githubusercontent.com/givps/AutoScriptXray/master/menu/versi 2>/dev/null || echo "2.0")
    echo "$server_version" > /opt/.ver
    
    # Save server IP
    if command -v get_ip_address >/dev/null 2>&1; then
        get_ip_address > /etc/myipvps 2>/dev/null || curl -sS ipv4.icanhazip.com > /etc/myipvps 2>/dev/null || true
    else
        curl -sS ipv4.icanhazip.com > /etc/myipvps 2>/dev/null || true
    fi
    
    # Create VPS info configuration
    echo "IP=" >> /var/lib/ipvps.conf
    
    show_success "Installation finalized"
}
# Function to display installation summary
display_installation_summary() {
    local end_time
    end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    
    clear
    echo ""
    echo "=================================================================="  | tee -a log-install.txt
    echo "              AutoScriptXray Installation Complete               "  | tee -a log-install.txt
    echo "=================================================================="  | tee -a log-install.txt
    echo ""
    echo "   >>> Service & Port Information"  | tee -a log-install.txt
    echo "   - OpenSSH                  : 22/110"  | tee -a log-install.txt
    echo "   - SSH Websocket            : 80" | tee -a log-install.txt
    echo "   - SSH SSL Websocket        : 443" | tee -a log-install.txt
    echo "   - Stunnel4                 : 222, 777" | tee -a log-install.txt
    echo "   - Dropbear                 : 109, 143" | tee -a log-install.txt
    echo "   - Badvpn                   : 7100-7900" | tee -a log-install.txt
    echo "   - Nginx                    : 81" | tee -a log-install.txt
    echo ""
    echo "   >>> Xray Services"  | tee -a log-install.txt
    echo "   - Vmess WS TLS             : 443" | tee -a log-install.txt
    echo "   - Vless WS TLS             : 443" | tee -a log-install.txt
    echo "   - Trojan WS TLS            : 443" | tee -a log-install.txt
    echo "   - Shadowsocks WS TLS       : 443" | tee -a log-install.txt
    echo "   - Vmess WS none TLS        : 80" | tee -a log-install.txt
    echo "   - Vless WS none TLS        : 80" | tee -a log-install.txt
    echo "   - Trojan WS none TLS       : 80" | tee -a log-install.txt
    echo "   - Shadowsocks WS none TLS  : 80" | tee -a log-install.txt
    echo "   - Vmess gRPC               : 443" | tee -a log-install.txt
    echo "   - Vless gRPC               : 443" | tee -a log-install.txt
    echo "   - Trojan gRPC              : 443" | tee -a log-install.txt
    echo "   - Shadowsocks gRPC         : 443" | tee -a log-install.txt
    echo ""
    echo "==================================================================" | tee -a log-install.txt
    echo "                    Support & Documentation                       " | tee -a log-install.txt  
    echo "                       t.me/givpn_grup                           " | tee -a log-install.txt
    echo "==================================================================" | tee -a log-install.txt
    echo "" | tee -a log-install.txt
    
    display_installation_time "$total_time" | tee -a log-install.txt
    echo ""
}

# Function to cleanup and reboot
cleanup_and_reboot() {
    show_info "Cleaning up installation files..."
    
    # Remove installation scripts
    rm -f /root/setup.sh /root/ins-xray.sh /root/insshws.sh /root/cf 2>/dev/null || true
    rm -f ssh-vpn.sh ins-xray.sh insshws.sh cf 2>/dev/null || true
    
    show_success "Installation completed successfully!"
    echo ""
    echo -e "${BGreen}The system will reboot in 10 seconds to complete the installation${NC}"
    echo -e "${BYellow}After reboot, you can access the menu by typing: menu${NC}"
    echo ""
    
    sleep 10
    reboot
}

# =========================================
# MAIN INSTALLATION PROCESS
# =========================================

main() {
    clear
    echo -e "${BBlue}"
    echo "=================================================================="
    echo "                AutoScriptXray Installation                      "
    echo "                    Edition: Stable 2.0                         "
    echo "=================================================================="
    echo -e "${NC}"
    
    # Execute installation steps
    validate_system_requirements
    configure_system_basics
    setup_directories
    install_kernel_headers
    install_essential_packages
    configure_domain
    install_ssh_services
    install_xray_services
    configure_user_profile
    setup_logging_system
    finalize_installation
    display_installation_summary
    cleanup_and_reboot
}

# Start the installation process
main "$@"

