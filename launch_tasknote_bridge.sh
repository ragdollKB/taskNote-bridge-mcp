#!/bin/bash

# TaskNote Bridge MCP Server Launch Script
# This script launches the TaskNote Bridge app in stdio mode for MCP clients like Claude Desktop

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Path to the TaskNote Bridge app
APP_PATH="$SCRIPT_DIR/TaskNote Bridge.app/Contents/MacOS/TaskNote Bridge"

# Check if the app exists
if [ ! -f "$APP_PATH" ]; then
    echo "Error: TaskNote Bridge.app not found at expected location: $APP_PATH" >&2
    echo "Please ensure TaskNote Bridge.app is in the same directory as this script." >&2
    exit 1
fi

# Launch in stdio mode
exec "$APP_PATH" --stdio
