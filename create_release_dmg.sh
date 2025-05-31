#!/bin/bash

# TaskNote Bridge DMG Creation Script
# Creates a professional installer DMG for GitHub releases

set -e

APP_NAME="TaskNote Bridge"
APP_BUNDLE="TaskNote Bridge.app"
VERSION="1.1.0"
DMG_NAME="TaskNote-Bridge-v${VERSION}"
TEMP_DMG="temp_${DMG_NAME}.dmg"
FINAL_DMG="${DMG_NAME}.dmg"

echo "🚀 Creating DMG for ${APP_NAME} v${VERSION}..."

# Check if app exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌ Error: ${APP_BUNDLE} not found!"
    echo "Run 'xcodebuild' to build the app first."
    exit 1
fi

# Clean up any existing files
rm -rf "${TEMP_DMG}" "${FINAL_DMG}" dmg_temp

# Create temporary directory
mkdir dmg_temp
cp -R "${APP_BUNDLE}" dmg_temp/

# Create alias to Applications folder
ln -s /Applications dmg_temp/Applications

# Add README for users
cat > dmg_temp/README.txt << EOF
TaskNote Bridge - MCP Server for Things 3 & Apple Notes

INSTALLATION:
1. Drag "TaskNote Bridge.app" to the Applications folder
2. Open the app to start the MCP server
3. Configure VS Code with the provided settings

For setup instructions, visit:
https://github.com/yourusername/tasknote-bridge

Requirements:
- macOS 12.0 or later
- Things 3 (for task management)
- Apple Notes (for note creation)
- VS Code with MCP extension

Version: ${VERSION}
EOF

# Calculate size and create DMG
SIZE=$(du -sm dmg_temp | cut -f1)
SIZE=$((SIZE + 10))  # Add some padding

echo "📦 Creating temporary DMG (${SIZE}MB)..."
hdiutil create -srcfolder dmg_temp -volname "${APP_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}m "${TEMP_DMG}"

# Mount the DMG
echo "📂 Mounting DMG for customization..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${TEMP_DMG}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
VOLUME="/Volumes/${APP_NAME}"

# Wait for mount
sleep 3

# Set DMG window properties (simplified version)
echo "🎨 Customizing DMG appearance..."
osascript << EOF || echo "Warning: DMG styling failed, continuing..."
tell application "Finder"
    try
        tell disk "${APP_NAME}"
            open
            set current view of container window to icon view
            set the bounds of container window to {400, 100, 900, 400}
            set theViewOptions to the icon view options of container window
            set icon size of theViewOptions to 128
            close
        end tell
        delay 2
    end try
end tell
EOF

# Ensure we can detach properly
sleep 2
sync

# Detach the DMG
echo "📤 Detaching DMG..."
hdiutil detach "${DEVICE}" || hdiutil detach "${DEVICE}" -force

# Convert to final compressed DMG
echo "🗜️  Converting to final compressed DMG..."
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# Clean up
rm -rf dmg_temp "${TEMP_DMG}"

# Get file size
SIZE_MB=$(du -m "${FINAL_DMG}" | cut -f1)
echo "✅ DMG created successfully!"
echo "📁 File: ${FINAL_DMG}"
echo "📊 Size: ${SIZE_MB}MB"
echo ""
echo "🚀 Ready for GitHub release!"
echo "Upload this DMG to your GitHub release page."
