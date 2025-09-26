#!/bin/bash
# AutoScriptXray User Management Library Functions
# Edition : Stable Edition 2.0
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

# Source common functions
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Function to get user input with validation and duplicate checking
get_new_username() {
    local config_file="$1"
    local service_type="$2"
    local user user_exists
    
    show_header "${service_type^^} ACCOUNT"
    
    while true; do
        read -rp "Username: " -e user
        
        # Validate username format
        if ! validate_username "$user"; then
            show_error "Invalid username format. Use only letters, numbers, and underscores."
            continue
        fi
        
        # Check if user already exists
        if [[ -f "$config_file" ]]; then
            user_exists=$(grep -wc "$user" "$config_file" 2>/dev/null || echo "0")
        else
            user_exists="0"
        fi
        
        if [[ "$user_exists" != "0" ]]; then
            clear
            show_header "${service_type^^} ACCOUNT"
            show_error "A client with the specified name already exists. Please choose another name."
            wait_for_keypress "Press any key to continue"
            show_header "${service_type^^} ACCOUNT"
            continue
        fi
        
        break
    done
    
    echo "$user"
}

# Function to get expiry date input
get_expiry_date() {
    local days
    
    while true; do
        read -rp "Expired (days): " -e days
        
        # Validate input is a number
        if ! [[ "$days" =~ ^[0-9]+$ ]]; then
            show_error "Please enter a valid number of days"
            continue
        fi
        
        # Check reasonable limits
        if [[ "$days" -lt 1 || "$days" -gt 3650 ]]; then
            show_error "Please enter a number between 1 and 3650 days"
            continue
        fi
        
        break
    done
    
    calculate_expiry "$days"
}

# Function to create user account configuration
create_user_config() {
    local username="$1"
    local expiry="$2"
    local uuid="$3"
    local service_type="$4"
    local config_file="$5"
    
    # Generate UUID if not provided
    if [[ -z "$uuid" ]]; then
        if command -v uuidgen >/dev/null 2>&1; then
            uuid=$(uuidgen)
        else
            # Fallback UUID generation
            uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16 | sed 's/\(..\)/\1-/g; s/.$//')
        fi
    fi
    
    # Log user creation
    log_user_creation "$username" "$service_type"
    
    echo "$uuid"
}

# Function to display user account information
show_account_info() {
    local username="$1"
    local expiry="$2"
    local uuid="$3"
    local domain="$4"
    local service_type="$5"
    local tls_port="$6"
    local ntls_port="$7"
    
    clear
    show_header "${service_type^^} ACCOUNT CREATED"
    
    echo -e "${CYAN}Remarks${NC}     : $username"
    echo -e "${CYAN}Domain${NC}      : $domain"
    echo -e "${CYAN}User ID${NC}     : $uuid"
    echo -e "${CYAN}Port TLS${NC}    : $tls_port"
    echo -e "${CYAN}Port none TLS${NC}: $ntls_port"
    echo -e "${CYAN}Created${NC}     : $(date '+%Y-%m-%d')"
    echo -e "${CYAN}Expired${NC}     : $expiry"
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to delete user from configuration
delete_user_from_config() {
    local username="$1"
    local config_file="$2"
    local service_type="$3"
    
    if [[ ! -f "$config_file" ]]; then
        show_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check if user exists
    if ! check_user_exists "$username" "$config_file"; then
        show_error "User '$username' not found"
        return 1
    fi
    
    # Create backup
    cp "$config_file" "${config_file}.backup.$(date +%s)"
    
    # Remove user entries
    sed -i "/^#&# $username /d" "$config_file"
    sed -i "/^### $username /,/^},{/d" "$config_file"
    
    show_success "User '$username' deleted successfully"
    log_user_creation "$username" "${service_type}-deleted"
    
    return 0
}

# Function to list users from config file
list_users() {
    local config_file="$1"
    local service_type="$2"
    
    if [[ ! -f "$config_file" ]]; then
        show_error "Configuration file not found: $config_file"
        return 1
    fi
    
    local users
    users=$(grep "^#&#" "$config_file" 2>/dev/null | cut -d ' ' -f 2)
    
    if [[ -z "$users" ]]; then
        show_info "No users found for $service_type"
        return 0
    fi
    
    show_header "${service_type^^} USER LIST"
    echo -e "${CYAN}Active users:${NC}"
    echo "$users" | nl -w2 -s'. '
    echo ""
}

# Function to check user login status
check_user_login() {
    local username="$1"
    local service_type="$2"
    local log_file="/var/log/xray/access.log"
    
    if [[ ! -f "$log_file" ]]; then
        show_error "Log file not found: $log_file"
        return 1
    fi
    
    local connections
    connections=$(grep -c "$username" "$log_file" 2>/dev/null || echo "0")
    
    show_header "${service_type^^} USER LOGIN STATUS"
    echo -e "${CYAN}Username${NC}: $username"
    echo -e "${CYAN}Connections${NC}: $connections"
    echo ""
}

# Export user management functions
export -f get_new_username get_expiry_date create_user_config show_account_info
export -f delete_user_from_config list_users check_user_login