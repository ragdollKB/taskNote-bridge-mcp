#!/bin/bash

# Test script to manually test tool call and capture errors

APP_PATH="${PWD}/build/Debug/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"

if [ ! -f "$APP_PATH" ]; then
    echo "App not found at: $APP_PATH"
    exit 1
fi

echo "Testing tool call with error capture..."

# Create a temporary script to test tool call
cat << 'EOF' > /tmp/test_mcp_tool.json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "bb7_add-todo", "arguments": {"title": "Error Test Task", "notes": "Testing for errors", "tags": ["error-test"]}}}
EOF

echo "Starting MCP server and sending test requests..."

# Run the app in stdio mode and pipe the test JSON
"$APP_PATH" --stdio < /tmp/test_mcp_tool.json

echo "Test completed."
rm -f /tmp/test_mcp_tool.json
