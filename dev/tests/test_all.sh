#!/bin/bash
# Run all tests for AutoScriptXray
# =================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

echo "AutoScriptXray Test Suite"
echo "========================="
echo ""

# Function to run a test script and collect results
run_test_script() {
    local test_script="$1"
    local test_name="$2"
    
    echo "Running $test_name..."
    echo "----------------------------------------"
    
    if [[ -f "$SCRIPT_DIR/$test_script" ]]; then
        if bash "$SCRIPT_DIR/$test_script"; then
            echo "✓ $test_name completed successfully"
        else
            echo "✗ $test_name had failures"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
    else
        echo "✗ Test script not found: $test_script"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    
    echo ""
}

# Make test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Run all test scripts
run_test_script "test_common.sh" "Common Library Tests"
run_test_script "test_menu.sh" "Menu Library Tests"

# Summary
echo "Test Suite Summary"
echo "=================="
echo "Test scripts run: $((TOTAL_FAILED + (TOTAL_FAILED == 0 ? 2 : 0)))"
echo "Test scripts passed: $((TOTAL_FAILED == 0 ? 2 : 2 - TOTAL_FAILED))"
echo "Test scripts failed: $TOTAL_FAILED"

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo ""
    echo "✓ All test suites passed!"
    exit 0
else
    echo ""
    echo "✗ Some test suites failed!"
    exit 1
fi