#!/bin/bash

# Swift MCP Server - stdio transport launcher
# This script launches the Things 3 MCP server in stdio mode for VS Code integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_SCRIPT="$SCRIPT_DIR/swift_mcp_stdio.swift"

# Check if the Swift script exists
if [ ! -f "$SWIFT_SCRIPT" ]; then
    echo "Error: Swift MCP script not found at $SWIFT_SCRIPT" >&2
    exit 1
fi

# Make sure it's executable
chmod +x "$SWIFT_SCRIPT"

# Launch the Swift MCP server in stdio mode
exec swift "$SWIFT_SCRIPT"
