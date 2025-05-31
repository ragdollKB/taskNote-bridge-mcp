#!/bin/bash

echo "=== Testing Claude Desktop's Exact Command ==="
echo "Command: /Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge --stdio"
echo ""

# Test 1: Check if app exists at Claude's path
if [ -f "/Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge" ]; then
    echo "✅ App exists at Claude Desktop path"
else
    echo "❌ App NOT found at Claude Desktop path"
    echo "Available files in /Applications:"
    ls -la /Applications/ | grep -i tasknote || echo "No TaskNote Bridge app found"
    exit 1
fi

# Test 2: Check app permissions
echo ""
echo "=== App Permissions ==="
ls -la "/Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"

# Test 3: Test initialization sequence (what Claude Desktop does)
echo ""
echo "=== Testing MCP Initialization Sequence ==="
echo "Sending initialize request..."

# Create test input that mimics Claude Desktop's behavior
cat << 'EOF' > /tmp/mcp_test_input.json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "clientInfo": {"name": "claude-desktop", "version": "0.5.0"}}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
EOF

echo "Input sequence:"
cat /tmp/mcp_test_input.json
echo ""
echo ""

echo "=== Server Response ==="
cat /tmp/mcp_test_input.json | "/Applications/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge" --stdio

# Clean up
rm -f /tmp/mcp_test_input.json

echo ""
echo "=== Test Complete ==="
