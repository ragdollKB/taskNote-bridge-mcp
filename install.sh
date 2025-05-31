#!/bin/bash

# Install the Things MCP app to the Applications folder
# This script copies the app bundle to the Applications folder and creates necessary symlinks

# Define paths
SOURCE_APP="$(dirname "$0")/Things MCP.app"
DEST_APP="/Applications/Things MCP.app"

# Inform user
echo "🚀 Installing Things MCP to Applications folder..."

# Check if the app exists
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ Error: Could not find Things MCP.app in the current directory."
    exit 1
fi

# Check if the app is already installed
if [ -d "$DEST_APP" ]; then
    echo "⚠️  Warning: Things MCP.app already exists in Applications folder."
    read -p "Do you want to replace it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo "Removing existing installation..."
    rm -rf "$DEST_APP"
fi

# Copy the app to Applications
echo "📦 Copying Things MCP.app to Applications folder..."
cp -R "$SOURCE_APP" "$DEST_APP"

# Create launcher scripts for convenience
echo "🔗 Creating launcher scripts..."

# Create a symlink to the launcher in the project directory
ln -sf "$DEST_APP/Contents/Resources/launch_mcp_server.sh" "$(dirname "$0")/launch_mcp_server.sh"

# Make the launcher executable
chmod +x "$DEST_APP/Contents/Resources/launch_mcp_server.sh"

echo "✅ Installation complete!"
echo
echo "To configure VS Code:"
echo "1. Open VS Code settings.json"
echo "2. Add this configuration:"
echo '{
    "mcp": {
        "inputs": [],
        "servers": {
            "things-swift": {
                "command": "/Applications/Things MCP.app/Contents/Resources/launch_mcp_server.sh",
                "args": []
            }
        }
    }
}'
echo
echo "To configure Claude Desktop:"
echo "1. Open claude_desktop_config.json"
echo "2. Add this configuration:"
echo '{
    "mcpServers": {
        "things": {
            "command": "/Applications/Things MCP.app/Contents/Resources/launch_mcp_server.sh",
            "args": []
        }
    }
}'
