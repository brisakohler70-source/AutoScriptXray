#!/bin/bash
# Test script for common library functions
# =========================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source the common library
# shellcheck source=../lib/common.sh
source "$LIB_DIR/common.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function helper
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_return="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "Running test: $test_name"
    
    if eval "$test_command"; then
        local result=$?
        if [[ $result -eq ${expected_return:-0} ]]; then
            echo "✓ PASS: $test_name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo "✗ FAIL: $test_name (returned $result, expected ${expected_return:-0})"
        fi
    else
        echo "✗ FAIL: $test_name (command failed)"
    fi
    echo ""
}

echo "Testing AutoScriptXray Common Library Functions"
echo "==============================================="
echo ""

# Test IP address function
run_test "get_ip_address" "get_ip_address >/dev/null"

# Test username validation
run_test "validate_username valid" "validate_username 'testuser123'"
run_test "validate_username invalid" "validate_username 'test user'" 1

# Test password generation
run_test "generate_password" "test -n \"\$(generate_password)\""
run_test "generate_password length" "test \"\$(generate_password 8 | wc -c)\" -le 9"

# Test date calculation
run_test "calculate_expiry" "calculate_expiry 30 >/dev/null"

# Test domain retrieval (may fail if no config exists)
run_test "get_domain" "get_domain >/dev/null"

# Test color definitions
run_test "color_definitions" "test -n \"$RED\" && test -n \"$GREEN\" && test -n \"$NC\""

# Test message functions
run_test "show_error" "show_error 'test message' 2>/dev/null"
run_test "show_success" "show_success 'test message' >/dev/null"
run_test "show_info" "show_info 'test message' >/dev/null"

# Test cleanup function
run_test "cleanup_temp_files" "cleanup_temp_files"

echo "Test Results:"
echo "============="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed!"
    exit 1
fi