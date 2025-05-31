#!/bin/bash

# Simple test to see if we can trigger stdio mode
echo "=== Testing Stdio Mode Detection ==="

# Kill any running instances
pkill -f "TaskNote Bridge" 2>/dev/null || true
sleep 1

echo "Attempting to run app in background with stdio flag..."

# Try to run in background and check if it responds
APP_PATH="/Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"

echo "Testing with explicit input/output redirection..."

# Create a named pipe for testing
mkfifo /tmp/mcp_test_pipe 2>/dev/null || true

# Send a test message
(
    echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
    sleep 2
) | "$APP_PATH" --stdio &

PID=$!
echo "Started process with PID: $PID"

# Wait a moment then check if it's still running
sleep 3

if kill -0 $PID 2>/dev/null; then
    echo "Process is still running - might be waiting for input"
    kill $PID 2>/dev/null
else
    echo "Process exited"
fi

# Clean up
rm -f /tmp/mcp_test_pipe

echo "Test completed."
