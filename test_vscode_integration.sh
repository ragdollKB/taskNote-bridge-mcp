#!/bin/bash

# Test VS Code MCP integration with stdio server
# This simulates how VS Code MCP extension would interact with our server

echo "🔧 Testing VS Code MCP Integration with stdio server..."
echo ""

# Test 1: Initialize protocol
echo "1️⃣ Testing MCP initialization..."
INIT_REQUEST='{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "clientInfo": {"name": "vscode-test", "version": "1.0.0"}}}'

echo "Request: $INIT_REQUEST"
echo "Response:"
echo "$INIT_REQUEST" | ./launch_swift_mcp_stdio.sh
echo ""

# Test 2: List available tools
echo "2️⃣ Testing tools/list..."
LIST_REQUEST='{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}'

echo "Request: $LIST_REQUEST"
echo "Response:"
echo "$LIST_REQUEST" | ./launch_swift_mcp_stdio.sh
echo ""

# Test 3: Call bb7_add-todo tool
echo "3️⃣ Testing bb7_add-todo tool call..."
TODO_REQUEST='{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "bb7_add-todo", "arguments": {"title": "VS Code Integration Test", "notes": "This task was created via VS Code MCP integration test", "tags": ["vscode", "test", "integration"]}}}'

echo "Request: $TODO_REQUEST"
echo "Response:"
echo "$TODO_REQUEST" | ./launch_swift_mcp_stdio.sh
echo ""

echo "✅ VS Code integration test complete!"
echo "Check Things 3 to verify the task was created."
