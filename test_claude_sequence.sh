#!/bin/bash

# Test script to simulate Claude Desktop's exact MCP sequence
echo "=== Simulating Claude Desktop MCP Communication ==="

APP_PATH="/Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"

# Create a temporary file for the input sequence
cat > claude_sequence.json << 'EOF'
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "clientInfo": {"name": "claude-desktop", "version": "0.5.0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
EOF

echo "Input sequence:"
cat claude_sequence.json
echo -e "\n\n=== Server Response ==="

# Send the sequence to the server
cat claude_sequence.json | "$APP_PATH" --stdio

echo -e "\n=== Test Complete ==="
