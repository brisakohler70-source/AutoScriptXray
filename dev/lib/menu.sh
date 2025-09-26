#!/bin/bash
# AutoScriptXray Menu Library Functions
# Edition : Stable Edition 2.0
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

# Source common functions
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Function to handle menu selection with validation
handle_menu_selection() {
    local choice="$1"
    shift
    local -a options=("$@")
    
    case "$choice" in
        0) clear; menu; return 0 ;;
        x) exit 0 ;;
        *)
            # Check if choice is valid
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -gt 0 ]] && [[ "$choice" -le ${#options[@]} ]]; then
                # Execute the corresponding function
                clear
                "${options[$((choice-1))]}"
                return $?
            else
                show_error "Invalid selection"
                sleep 1
                return 1
            fi
            ;;
    esac
}

# Function to display SSH/OpenVPN menu
show_ssh_menu() {
    show_header "SSH MENU"
    show_menu_option "1" "Create SSH & WS Account"
    show_menu_option "2" "Trial SSH & WS Account"
    show_menu_option "3" "Renew SSH & WS Account"
    show_menu_option "4" "Delete SSH & WS Account"
    show_menu_option "5" "Check User Login SSH & WS"
    show_menu_option "6" "Show User Created Account"
    show_menu_option "7" "Delete User Expired Account"
    show_menu_option "8" "Setup Autokill SSH"
    show_menu_option "9" "Display Multi Login SSH"
    show_menu_option "10" "Show SSH & WS Log"
    show_menu_option "11" "Edit Banner SSH"
    show_menu_option "12" "User Lock SSH & WS"  
    show_menu_option "13" "User Unlock SSH & WS"
    show_menu_footer
    
    local choice
    choice=$(read_menu_choice "Select menu")
    handle_menu_selection "$choice" "usernew" "trial" "renew" "hapus" "cek" "member" "delete" "autokill" "ceklim" "cat /etc/log-create-ssh.log" "nano /etc/issue.net" "user-lock" "user-unlock"
}

# Function to display VMESS menu
show_vmess_menu() {
    show_header "VMESS MENU"
    show_menu_option "1" "Create Account Vmess"
    show_menu_option "2" "Trial Account Vmess"
    show_menu_option "3" "Extending Account Vmess"
    show_menu_option "4" "Delete Account Vmess"
    show_menu_option "5" "Check User Login Vmess"
    show_menu_option "6" "User list created Account"
    show_menu_footer
    
    local choice
    choice=$(read_menu_choice "Select menu")
    handle_menu_selection "$choice" "add-ws" "trialvmess" "renew-ws" "del-ws" "cek-ws" "cat /etc/log-create-vmess.log"
}

# Function to display VLESS menu
show_vless_menu() {
    show_header "VLESS MENU"
    show_menu_option "1" "Create Account Vless"
    show_menu_option "2" "Trial Account Vless"
    show_menu_option "3" "Extending Account Vless"
    show_menu_option "4" "Delete Account Vless"
    show_menu_option "5" "Check User Login Vless"
    show_menu_option "6" "User list created Account"
    show_menu_footer
    
    local choice
    choice=$(read_menu_choice "Select menu")
    handle_menu_selection "$choice" "add-vless" "trialvless" "renew-vless" "del-vless" "cek-vless" "cat /etc/log-create-vless.log"
}

# Function to display Trojan menu
show_trojan_menu() {
    show_header "TROJAN MENU"
    show_menu_option "1" "Create Account Trojan"
    show_menu_option "2" "Trial Account Trojan"
    show_menu_option "3" "Extending Account Trojan"
    show_menu_option "4" "Delete Account Trojan"
    show_menu_option "5" "Check User Login Trojan"
    show_menu_option "6" "User list created Account"
    show_menu_footer
    
    local choice
    choice=$(read_menu_choice "Select menu")
    handle_menu_selection "$choice" "add-tr" "trialtrojan" "renew-tr" "del-tr" "cek-tr" "cat /etc/log-create-trojan.log"
}

# Function to display Shadowsocks menu
show_shadowsocks_menu() {
    show_header "Shadowsocks Account"
    show_menu_option "1" "Create Account Shadowsocks"
    show_menu_option "2" "Create Trial Shadowsocks"
    show_menu_option "3" "Extending Account Shadowsocks"
    show_menu_option "4" "Delete Account Shadowsocks"
    show_menu_option "5" "User list created Account"
    show_menu_footer
    
    local choice
    choice=$(read_menu_choice "Select menu")
    handle_menu_selection "$choice" "add-ssws" "trialssws" "renew-ssws" "del-ssws" "cat /etc/log-create-shadowsocks.log"
}

# Function to display System menu
show_system_menu() {
    show_header "SYSTEM MENU"
    show_menu_option "1" "Panel Domain"
    show_menu_option "2" "Speedtest VPS"
    show_menu_option "3" "Set Auto Reboot"
    show_menu_option "4" "Restart All Service"
    show_menu_option "5" "Cek Bandwith"
    show_menu_option "6" "Install TCP BBR"
    show_menu_option "7" "DNS CHANGER"
    show_menu_footer
    
    local choice
    choice=$(read_menu_choice "Select menu")
    handle_menu_selection "$choice" "m-domain" "speedtest" "auto-reboot" "restart" "bw" "m-tcp" "m-dns"
}

# Function to get system information
get_system_info() {
    local domain uptime name exp2
    
    # Get domain
    domain=$(get_domain)
    
    # Get uptime
    if command -v uptime >/dev/null 2>&1; then
        uptime=$(uptime -p | cut -d " " -f 2-10)
    else
        uptime="Unknown"
    fi
    
    # Get client name and expiry (simplified)
    if [[ -f /etc/xray/domain ]]; then
        name="VPS User"
        exp2="Check manually"
    else
        name="Unknown"
        exp2="Unknown"
    fi
    
    echo -e "${BYELLOW} -------------------------------------------------${NC}"
    echo -e "${BGREEN} Client Name ${NC}: $name"
    echo -e "${BGREEN} Expired     ${NC}: $exp2"
    echo -e "${BYELLOW} -------------------------------------------------${NC}"
}

# Export menu functions
export -f handle_menu_selection show_ssh_menu show_vmess_menu show_vless_menu
export -f show_trojan_menu show_shadowsocks_menu show_system_menu get_system_info