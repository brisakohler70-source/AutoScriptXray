# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-09-26

### Added
- Created `dev/` folder for developer documentation and utilities
- Added reusable function libraries in `dev/lib/`
- Added comprehensive test suite in `dev/tests/`
- Added developer documentation with clear architecture overview

### Changed
- **BREAKING CHANGE**: Refactored entire codebase to use reusable functions
- Reduced code duplication across 64+ shell scripts
- Standardized color definitions and UI elements
- Improved error handling and validation across all scripts
- Made all scripts shellcheck compliant

### Fixed
- Fixed various shellcheck warnings and errors
- Improved script reliability and error handling
- Standardized variable naming and quoting

### Removed
- Removed duplicate color definitions from individual scripts
- Removed repeated IP address fetching code
- Removed redundant menu display functions

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
- Significant code duplication across scripts
- Inconsistent error handling
- Multiple shellcheck violations
- Hardcoded values and poor modularity