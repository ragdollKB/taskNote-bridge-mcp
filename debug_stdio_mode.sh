#!/bin/bash

# Test script to debug TaskNote Bridge stdio mode
echo "=== Debugging TaskNote Bridge Stdio Mode ==="

APP_PATH="/Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"

# First, kill any running instances
pkill -f "TaskNote Bridge" 2>/dev/null || true
sleep 1

# Test 1: Check if we can detect command line args
echo "Test 1: Checking command line argument detection..."
echo "Running: $APP_PATH --stdio --debug"

# Use a timeout to prevent hanging
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | timeout 5 "$APP_PATH" --stdio

echo "Test completed."
