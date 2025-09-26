#!/bin/bash
# AutoScriptXray Common Library Functions
# Edition : Stable Edition 2.0
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

# Color definitions - centralized to avoid duplication
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly GREEN='\033[0;32m'
readonly ORANGE='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly LIGHT='\033[0;37m'
readonly YELLOW='\e[33m'
readonly LRED='\e[91m'
readonly LGREEN='\e[92m'
readonly LYELLOW='\e[93m'
readonly BGREEN='\e[1;32m'
readonly BYELLOW='\e[1;33m'
readonly BBLUE='\e[1;34m'
readonly BPURPLE='\e[1;35m'
readonly BCYAN='\e[1;36m'

# Function to get server IP address with error handling
get_ip_address() {
    local ip
    # Try multiple methods to get IP address
    if command -v curl >/dev/null 2>&1; then
        ip=$(curl -sS --connect-timeout 10 ipv4.icanhazip.com 2>/dev/null)
    elif command -v wget >/dev/null 2>&1; then
        ip=$(wget -qO- --timeout=10 ipv4.icanhazip.com 2>/dev/null)
    fi
    
    # Validate IP format
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo "Unable to determine IP address" >&2
        return 1
    fi
}

# Function to display standardized headers
show_header() {
    local title="$1"
    local width=33
    
    clear
    echo "Checking VPS"
    clear
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "${BBLUE}%*s${NC}\n" $(((${#title} + width) / 2)) "$title"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to display menu options
show_menu_option() {
    local number="$1"
    local description="$2"
    printf " [${CYAN}•%s${NC}] %s\n" "$number" "$description"
}

# Function to display back/exit options
show_menu_footer() {
    echo ""
    echo -e " [${RED}•0${NC}] ${RED}Back To Menu${NC}"
    echo -e ""
    echo -e "Press x or [ Ctrl+C ] • To-Exit"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to read menu selection with validation
read_menu_choice() {
    local prompt="$1"
    local choice
    read -rp " $prompt: " choice
    echo ""
    echo "$choice"
}

# Function to validate username format
validate_username() {
    local username="$1"
    if [[ $username =~ ^[a-zA-Z0-9_]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if user exists in config
check_user_exists() {
    local username="$1"
    local config_file="$2"
    if [[ -f "$config_file" ]]; then
        grep -wq "$username" "$config_file"
    else
        return 1
    fi
}

# Function to display error messages
show_error() {
    local message="$1"
    echo -e "${RED}Error: $message${NC}" >&2
}

# Function to display success messages
show_success() {
    local message="$1"
    echo -e "${GREEN}Success: $message${NC}"
}

# Function to display info messages
show_info() {
    local message="$1"
    echo -e "${CYAN}Info: $message${NC}"
}

# Function to get domain from config
get_domain() {
    local domain
    if [[ -f /etc/xray/domain ]]; then
        domain=$(cat /etc/xray/domain)
    elif [[ -f /var/lib/ipvps.conf ]]; then
        # shellcheck source=/dev/null
        source /var/lib/ipvps.conf
        if [[ -n "$IP" ]]; then
            domain="$IP"
        fi
    fi
    
    if [[ -z "$domain" ]]; then
        domain=$(get_ip_address)
    fi
    
    echo "$domain"
}

# Function to get port from log file
get_port_from_log() {
    local service_name="$1"
    local log_file="$HOME/log-install.txt"
    local port
    
    if [[ -f "$log_file" ]]; then
        port=$(grep -w "$service_name" "$log_file" | cut -d: -f2 | sed 's/ //g')
        echo "$port"
    else
        show_error "Log file not found: $log_file"
        return 1
    fi
}

# Function to restart xray service safely
restart_xray() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart xray
        return $?
    else
        show_error "systemctl not available"
        return 1
    fi
}

# Function to cleanup temporary files
cleanup_temp_files() {
    local temp_dir="/tmp"
    rm -rf "$temp_dir"/log "$temp_dir"/log1 "$temp_dir"/iptrojan.txt "$temp_dir"/other.txt 2>/dev/null
}

# Function to wait for user input
wait_for_keypress() {
    local message="${1:-Press any key to continue}"
    read -n 1 -s -r -p "$message"
    echo ""
}

# Function to log user creation
log_user_creation() {
    local username="$1"
    local service_type="$2"
    local log_file="/etc/log-create-${service_type}.log"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] User created: $username" >> "$log_file"
}

# Function to generate random password
generate_password() {
    local length="${1:-12}"
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
    else
        # Fallback method
        date +%s | sha256sum | base64 | head -c "$length"
    fi
}

# Function to validate date format
validate_date() {
    local date_string="$1"
    if date -d "$date_string" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to calculate expiration date
calculate_expiry() {
    local days="$1"
    if command -v date >/dev/null 2>&1; then
        date -d "+${days} days" '+%Y-%m-%d'
    else
        show_error "date command not available"
        return 1
    fi
}

# Export functions for use in other scripts
export -f get_ip_address show_header show_menu_option show_menu_footer
export -f read_menu_choice validate_username check_user_exists
export -f show_error show_success show_info get_domain get_port_from_log
export -f restart_xray cleanup_temp_files wait_for_keypress log_user_creation
export -f generate_password validate_date calculate_expiry