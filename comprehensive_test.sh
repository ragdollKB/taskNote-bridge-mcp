#!/bin/bash

# Comprehensive MCP Server Test Suite
# Tests all functionality of the TaskNote Bridge MCP Server

set -e

APP_PATH="./TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"
TEST_LOG="test_results.log"

echo "🧪 Starting Comprehensive MCP Server Test Suite" | tee $TEST_LOG
echo "📅 Test Date: $(date)" | tee -a $TEST_LOG
echo "================================================" | tee -a $TEST_LOG

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -e "\n${YELLOW}Testing: $test_name${NC}" | tee -a $TEST_LOG
    echo "Command: $test_command" | tee -a $TEST_LOG
    
    if result=$(eval "$test_command" 2>&1); then
        if [[ "$expected_result" == "" ]] || echo "$result" | grep -q "$expected_result"; then
            echo -e "${GREEN}✅ PASS${NC}" | tee -a $TEST_LOG
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ FAIL - Expected: $expected_result${NC}" | tee -a $TEST_LOG
            echo "Got: $result" | tee -a $TEST_LOG
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}❌ FAIL - Command failed${NC}" | tee -a $TEST_LOG
        echo "Error: $result" | tee -a $TEST_LOG
        ((TESTS_FAILED++))
    fi
}

# Check if app exists
if [[ ! -f "$APP_PATH" ]]; then
    echo -e "${RED}❌ TaskNote Bridge app not found at: $APP_PATH${NC}"
    exit 1
fi

echo -e "\n${YELLOW}🔍 Phase 1: Basic Protocol Tests${NC}" | tee -a $TEST_LOG

# Test 1: Initialize Request
run_test "Initialize Handshake" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"initialize\", \"params\": {\"protocolVersion\": \"2024-11-05\", \"capabilities\": {}, \"clientInfo\": {\"name\": \"test-client\", \"version\": \"1.0.0\"}}}" | "$APP_PATH" --stdio | jq ".result.serverInfo.name"' \
    '"TaskNote-Bridge-MCP"'

# Test 2: Tools List
run_test "Tools List Request" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 2, \"method\": \"tools/list\"}" | "$APP_PATH" --stdio | jq ".result.tools | length"' \
    "10"

# Test 3: Verify specific tools exist
run_test "Check bb7_add-todo exists" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 3, \"method\": \"tools/list\"}" | "$APP_PATH" --stdio | jq ".result.tools[0].name"' \
    '"bb7_add-todo"'

echo -e "\n${YELLOW}🔍 Phase 2: Things 3 Tool Tests${NC}" | tee -a $TEST_LOG

# Test 4: Add Todo Tool (dry run - just check response format)
run_test "bb7_add-todo Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 4, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_add-todo\", \"arguments\": {\"title\": \"Test Task from MCP\"}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

# Test 5: Add Project Tool
run_test "bb7_add-project Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 5, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_add-project\", \"arguments\": {\"title\": \"Test Project from MCP\"}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

# Test 6: Search Todos Tool
run_test "bb7_search-todos Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 6, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_search-todos\", \"arguments\": {\"query\": \"test\"}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

# Test 7: Get Today Tool
run_test "bb7_get-today Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 7, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_get-today\", \"arguments\": {}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

# Test 8: Get Projects Tool
run_test "bb7_get-projects Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 8, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_get-projects\", \"arguments\": {}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

echo -e "\n${YELLOW}🔍 Phase 3: Apple Notes Tool Tests${NC}" | tee -a $TEST_LOG

# Test 9: Create Note Tool
run_test "bb7_notes-create Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 9, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_notes-create\", \"arguments\": {\"title\": \"MCP Test Note\", \"content\": \"This is a test note created via MCP\"}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

# Test 10: List Notes Tool
run_test "bb7_notes-list Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 10, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_notes-list\", \"arguments\": {}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

# Test 11: Search Notes Tool
run_test "bb7_notes-search Tool Call" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 11, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_notes-search\", \"arguments\": {\"query\": \"MCP\"}}}" | "$APP_PATH" --stdio | jq ".result.content[0].type"' \
    '"text"'

echo -e "\n${YELLOW}🔍 Phase 4: Error Handling Tests${NC}" | tee -a $TEST_LOG

# Test 12: Invalid Tool Name
run_test "Invalid Tool Name" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 12, \"method\": \"tools/call\", \"params\": {\"name\": \"invalid_tool\", \"arguments\": {}}}" | "$APP_PATH" --stdio | jq ".error.code"' \
    "-32001"

# Test 13: Missing Required Parameter
run_test "Missing Required Parameter" \
    'echo "{\"jsonrpc\": \"2.0\", \"id\": 13, \"method\": \"tools/call\", \"params\": {\"name\": \"bb7_add-todo\", \"arguments\": {}}}" | "$APP_PATH" --stdio | jq ".error.code"' \
    "-32602"

# Test 14: Invalid JSON
run_test "Invalid JSON Handling" \
    'echo "{invalid json}" | "$APP_PATH" --stdio | jq ".error.code"' \
    "-32700"

echo -e "\n${YELLOW}🔍 Phase 5: Performance Tests${NC}" | tee -a $TEST_LOG

# Test 15: Multiple rapid requests
run_test "Multiple Rapid Requests" \
    'for i in {1..5}; do echo "{\"jsonrpc\": \"2.0\", \"id\": $i, \"method\": \"tools/list\"}"; done | "$APP_PATH" --stdio | jq -s "length"' \
    "5"

echo -e "\n================================================" | tee -a $TEST_LOG
echo -e "${YELLOW}📊 Test Results Summary:${NC}" | tee -a $TEST_LOG
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}" | tee -a $TEST_LOG
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}" | tee -a $TEST_LOG

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! MCP Server is fully functional!${NC}" | tee -a $TEST_LOG
    exit 0
else
    echo -e "\n${RED}⚠️  Some tests failed. Check the log for details.${NC}" | tee -a $TEST_LOG
    exit 1
fi
