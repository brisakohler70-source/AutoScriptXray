# Developer Documentation

This folder contains developer documentation, tests, and utilities for the AutoScriptXray project.

## Structure

- `README.md` - This file
- `CHANGELOG.md` - Project changelog
- `tests/` - Test scripts for functionality verification
- `lib/` - Reusable function libraries

## Project Overview

AutoScriptXray is a VPS setup and management script collection for various protocols including:
- SSH/Websocket services
- Xray (VLESS, VMESS, Trojan)
- Shadowsocks
- OpenVPN
- System utilities

## Architecture

The project has been refactored to use reusable function libraries to reduce code duplication and improve maintainability.

### Original Structure Issues
- 64+ shell scripts with significant code duplication
- Repeated color definitions and UI elements
- Similar menu patterns across different modules
- Inconsistent error handling and logging

### New Structure
- Common functions extracted to `lib/` directory
- Consistent error handling and validation
- Modular and maintainable code
- Shellcheck compliant scripts

## Running Tests

```bash
cd dev/tests
chmod +x test_*.sh
./test_all.sh
```

## Using Library Functions

```bash
# Source the common library
source /path/to/dev/lib/common.sh

# Use common functions
show_header "My Menu Title"
get_ip_address
validate_user_input "username"
```