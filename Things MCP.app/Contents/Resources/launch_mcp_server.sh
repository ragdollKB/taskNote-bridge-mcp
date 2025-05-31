#!/bin/bash

# MCP Server launcher script for Things MCP.app
# This script runs the Python MCP server bundled in the app's Resources folder

# Set up environment
export PYTHONUNBUFFERED=1

# Get the directory where this script is located (Resources directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get the project root (go up from Things MCP.app/Contents/Resources to project directory)
PROJECT_ROOT="$SCRIPT_DIR/../../.."

# Use the virtual environment Python to run the server
"$PROJECT_ROOT/.venv/bin/python" "$SCRIPT_DIR/things_server.py"
