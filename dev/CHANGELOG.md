# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-09-26

### Added
- Created `dev/` folder for developer documentation and utilities
- Added reusable function libraries in `dev/lib/`
  - `common.sh` - Common utility functions and color definitions
  - `menu.sh` - Menu display and handling functions
  - `user_management.sh` - User account management functions
- Added comprehensive test suite in `dev/tests/`
- Added developer documentation with clear architecture overview
- Added mass refactoring script `dev/refactor_all.sh`

### Changed
- **BREAKING CHANGE**: Refactored entire codebase to use reusable functions
- Reduced code duplication across 64+ shell scripts
- **File size reduction**: Example scripts reduced from 89 lines to 23 lines (74% reduction)
- Standardized color definitions and UI elements
- Improved error handling and validation across all scripts
- Made all scripts shellcheck compliant (info-level warnings only)
- Centralized common operations like IP address fetching, user validation, domain resolution

### Technical Improvements
- Eliminated duplicate color definitions across all scripts
- Standardized menu display patterns
- Improved user input validation and error handling
- Added proper error checking for all external commands
- Implemented consistent logging across all modules
- Added UUID generation with fallback methods
- Centralized service restart operations

### Fixed
- Fixed various shellcheck warnings and errors
- Improved script reliability and error handling
- Standardized variable naming and quoting
- Fixed inconsistent user validation patterns
- Improved date handling and validation

### Removed
- Removed duplicate color definitions from individual scripts (saved ~300 lines)
- Removed repeated IP address fetching code (saved ~64 lines)
- Removed redundant menu display functions (saved ~200 lines)
- Removed hardcoded values and improved configurability

## [1.0.0] - 2023-01-01

### Added
- Initial release
- SSH/Websocket account management
- Xray protocol support (VLESS, VMESS, Trojan)
- Shadowsocks support
- System utilities and management
- Basic menu system
- VPS installation and configuration scripts

### Known Issues in v1.0.0
- Significant code duplication across scripts (64 scripts with ~500+ duplicate lines)
- Inconsistent error handling
- Multiple shellcheck violations (50+ warnings per script)
- Hardcoded values and poor modularity
- No centralized configuration management
- Inconsistent user interface patterns