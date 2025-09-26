#!/bin/bash
# AutoScriptXray Mass Refactoring Script
# Edition : Stable Edition 2.0
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_COUNT=0
REFACTORED_COUNT=0

# Function to display progress
show_progress() {
    local message="$1"
    echo -e "\e[1;32m[REFACTOR]\e[0m $message"
}

# Function to backup original file
backup_file() {
    local file="$1"
    cp "$file" "$file.backup.$(date +%s)"
}

# Function to check if file needs refactoring
needs_refactoring() {
    local file="$1"
    
    # Check if file contains old patterns
    if grep -q "MYIP=\$(wget" "$file" 2>/dev/null || \
       grep -q "RED='\\\\033\[0;31m'" "$file" 2>/dev/null || \
       grep -q "echo.*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$file" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Function to refactor menu scripts
refactor_menu_script() {
    local file="$1"
    local script_name
    script_name=$(basename "$file" .sh)
    local menu_function=""
    
    # Determine menu function based on script name
    case "$script_name" in
        "m-trojan") menu_function="show_trojan_menu" ;;
        "m-vless") menu_function="show_vless_menu" ;;
        "m-vmess") menu_function="show_vmess_menu" ;;
        "m-ssws") menu_function="show_shadowsocks_menu" ;;
        "m-sshovpn") menu_function="show_ssh_menu" ;;
        "m-system") menu_function="show_system_menu" ;;
        *) return 1 ;;
    esac
    
    backup_file "$file"
    
    cat > "$file" <<EOF
#!/bin/bash
# Quick Setup | Script Setup Manager
# Edition : Stable Edition 2.0 (Refactored)
# Author  : givps (refactored)
# The MIT License (MIT)
# (C) Copyright 2023-2024
# =========================================

# Source the menu library
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dev/lib/menu.sh
source "\$SCRIPT_DIR/../dev/lib/menu.sh"

# Main function to display menu
$script_name() {
    # If menu selection fails, retry
    if ! $menu_function; then
        show_error "Invalid selection"
        sleep 1
        $script_name
    fi
}

# Call main function
$script_name
EOF

    return 0
}

# Function to add library imports to xray scripts
add_library_imports() {
    local file="$1"
    local temp_file
    temp_file=$(mktemp)
    
    # Add library imports after shebang and comments
    {
        head -n 7 "$file"
        echo ""
        echo "# Source libraries"
        echo "SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\""
        echo "# shellcheck source=../dev/lib/common.sh"
        echo "source \"\$SCRIPT_DIR/../dev/lib/common.sh\""
        echo "# shellcheck source=../dev/lib/user_management.sh"
        echo "source \"\$SCRIPT_DIR/../dev/lib/user_management.sh\""
        echo ""
        tail -n +8 "$file" | sed '
            /^MYIP=/d
            /^RED=/d; /^NC=/d; /^GREEN=/d; /^ORANGE=/d; /^BLUE=/d; /^PURPLE=/d; /^CYAN=/d; /^LIGHT=/d
            /^echo "Checking VPS"$/d
            s/wget -qO- ipv4\.icanhazip\.com/get_ip_address/g
            s/echo -e "\\\\033\[0;31m\(.*\)\\\\033\[0m"/show_error "\1"/g
            s/echo -e "\\\\033\[0;32m\(.*\)\\\\033\[0m"/show_success "\1"/g
        '
    } > "$temp_file"
    
    mv "$temp_file" "$file"
}

# Main refactoring process
main() {
    show_progress "Starting mass refactoring of AutoScriptXray scripts"
    
    # Refactor menu scripts
    show_progress "Refactoring menu scripts..."
    for menu_file in "$REPO_ROOT"/menu/m-*.sh; do
        if [[ -f "$menu_file" ]]; then
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
            if needs_refactoring "$menu_file"; then
                show_progress "Refactoring $(basename "$menu_file")"
                if refactor_menu_script "$menu_file"; then
                    REFACTORED_COUNT=$((REFACTORED_COUNT + 1))
                fi
            fi
        fi
    done
    
    # Add library imports to xray scripts (partial refactoring)
    show_progress "Adding library imports to xray scripts..."
    for xray_file in "$REPO_ROOT"/xray/*.sh; do
        if [[ -f "$xray_file" && "$(basename "$xray_file")" != "add-tr.sh" ]]; then
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
            if needs_refactoring "$xray_file"; then
                show_progress "Adding libraries to $(basename "$xray_file")"
                backup_file "$xray_file"
                add_library_imports "$xray_file"
                REFACTORED_COUNT=$((REFACTORED_COUNT + 1))
            fi
        fi
    done
    
    show_progress "Refactoring complete!"
    echo "Scripts processed: $SCRIPT_COUNT"
    echo "Scripts refactored: $REFACTORED_COUNT"
    
    # Run shellcheck on refactored files
    show_progress "Running shellcheck on refactored files..."
    local shellcheck_errors=0
    for file in "$REPO_ROOT"/menu/m-*.sh "$REPO_ROOT"/xray/*.sh; do
        if [[ -f "$file" ]]; then
            if ! shellcheck "$file" >/dev/null 2>&1; then
                shellcheck_errors=$((shellcheck_errors + 1))
            fi
        fi
    done
    
    if [[ $shellcheck_errors -eq 0 ]]; then
        show_progress "All refactored scripts pass shellcheck!"
    else
        echo -e "\e[1;33m[WARNING]\e[0m $shellcheck_errors scripts have shellcheck warnings"
    fi
}

# Run main function
main "$@"