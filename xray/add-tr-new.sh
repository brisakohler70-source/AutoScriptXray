#!/bin/bash
# Quick Setup | Script Setup Manager
# Edition : Stable Edition 2.0 (Refactored)
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dev/lib/common.sh
source "$SCRIPT_DIR/../dev/lib/common.sh"
# shellcheck source=../dev/lib/user_management.sh
source "$SCRIPT_DIR/../dev/lib/user_management.sh"

# Main function to add Trojan user
add_trojan_user() {
    local user expiry uuid domain tls ntls
    local config_file="/etc/xray/config.json"
    
    # Get domain
    domain=$(get_domain)
    
    # Get port information
    tls=$(get_port_from_log "Trojan WS TLS" || echo "443")
    ntls=$(get_port_from_log "Trojan WS none TLS" || echo "80")
    
    # Get username with validation
    user=$(get_new_username "$config_file" "trojan")
    
    # Get expiry date
    expiry=$(get_expiry_date)
    
    # Create user configuration
    uuid=$(create_user_config "$user" "$expiry" "" "trojan" "$config_file")
    
    # Add user to xray configuration
    sed -i "/#trojan$/a\\#&# $user $expiry\\},{\"password\": \"$uuid\",\"email\": \"$user\"" "$config_file"
    sed -i "/#trojangrpc$/a\\#&# $user $expiry\\},{\"password\": \"$uuid\",\"email\": \"$user\"" "$config_file"
    
    # Restart xray service
    if restart_xray; then
        show_success "Xray service restarted successfully"
    else
        show_error "Failed to restart Xray service"
    fi
    
    # Generate connection links
    local trojanlink1="trojan://${uuid}@bug.com:$ntls?path=trojan-ws&security=none&host=${domain}&type=ws#${user}"
    local trojanlink2="trojan://${uuid}@${domain}:$tls?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${user}"
    
    # Display account information
    show_account_info "$user" "$expiry" "$uuid" "$domain" "trojan" "$tls" "$ntls"
    
    # Log links
    {
        echo "Link TLS       : $trojanlink1"
        echo "Link none TLS  : $trojanlink2"
        echo "Link gRPC      : $trojanlink1"
        echo "Expired On     : $expiry"
        echo ""
    } | tee -a /etc/log-create-trojan.log
    
    # Cleanup and return to menu
    cleanup_temp_files
    wait_for_keypress "Press any key to back on menu"
    
    if command -v m-trojan >/dev/null 2>&1; then
        m-trojan
    fi
}

# Call main function
add_trojan_user