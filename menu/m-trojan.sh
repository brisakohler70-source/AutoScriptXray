#!/bin/bash
# Quick Setup | Script Setup Manager
# Edition : Stable Edition 2.0 (Refactored)
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

# Source the menu library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dev/lib/menu.sh
source "$SCRIPT_DIR/../dev/lib/menu.sh"

# Main function to display Trojan menu
m-trojan() {
    # If menu selection fails, retry
    if ! show_trojan_menu; then
        show_error "Invalid selection"
        sleep 1
        m-trojan
    fi
}

# Call main function
m-trojan
