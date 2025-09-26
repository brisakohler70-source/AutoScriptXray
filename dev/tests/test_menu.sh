#!/bin/bash
# Test script for menu library functions
# =======================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source the menu library
# shellcheck source=../lib/menu.sh
source "$LIB_DIR/menu.sh"

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

echo "Testing AutoScriptXray Menu Library Functions"
echo "=============================================="
echo ""

# Test header display function
run_test "show_header" "show_header 'Test Menu' >/dev/null"

# Test menu option display
run_test "show_menu_option" "show_menu_option '1' 'Test Option' >/dev/null"

# Test menu footer display
run_test "show_menu_footer" "show_menu_footer >/dev/null"

# Test system info (may have issues without proper config)
run_test "get_system_info" "get_system_info >/dev/null"

# Test that menu functions are properly exported
run_test "function_exports" "declare -F show_header >/dev/null && declare -F show_menu_option >/dev/null"

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