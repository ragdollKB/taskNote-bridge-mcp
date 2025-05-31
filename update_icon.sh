#!/bin/bash

# TaskNote Bridge Icon Update Script
# Converts icon.jpeg to all required app icon formats

set -e

echo "🎨 Updating TaskNote Bridge app icon..."

# Check if source icon exists
if [ ! -f "icon.jpeg" ]; then
    echo "❌ Error: icon.jpeg not found!"
    exit 1
fi

# Check if we have sips (built into macOS)
if ! command -v sips &> /dev/null; then
    echo "❌ Error: sips command not found (required for image conversion)"
    exit 1
fi

# Create icon.iconset directory if it doesn't exist
mkdir -p icon.iconset

echo "📐 Converting icon to required sizes..."

# Generate all required icon sizes
sips -z 16 16 icon.jpeg --out icon.iconset/icon_16x16.png
sips -z 32 32 icon.jpeg --out icon.iconset/icon_16x16@2x.png
sips -z 32 32 icon.jpeg --out icon.iconset/icon_32x32.png
sips -z 64 64 icon.jpeg --out icon.iconset/icon_32x32@2x.png
sips -z 128 128 icon.jpeg --out icon.iconset/icon_128x128.png
sips -z 256 256 icon.jpeg --out icon.iconset/icon_128x128@2x.png
sips -z 256 256 icon.jpeg --out icon.iconset/icon_256x256.png
sips -z 512 512 icon.jpeg --out icon.iconset/icon_256x256@2x.png
sips -z 512 512 icon.jpeg --out icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.jpeg --out icon.iconset/icon_512x512@2x.png

echo "🗜️  Creating .icns file..."

# Convert iconset to .icns format
iconutil -c icns icon.iconset

echo "📋 Copying icon to project locations..."

# Copy main app icon (using 512x512 version)
cp icon.iconset/icon_512x512.png AppIcon.png

# Copy to source directory
cp AppIcon.png "TaskNote Bridge/AppIcon.png"

echo "🔨 Rebuilding app with new icon..."

# Build the app with new icon
xcodebuild -project "TaskNote Bridge.xcodeproj" -scheme "TaskNote Bridge" clean build

echo "📦 Copying updated app..."

# Copy the built app to the project directory
if [ -d "build/Debug/TaskNote Bridge.app" ]; then
    rm -rf "TaskNote Bridge.app"
    cp -R "build/Debug/TaskNote Bridge.app" .
    echo "✅ TaskNote Bridge.app updated with new icon!"
else
    echo "⚠️  Build completed but app not found in expected location"
fi

echo "🎉 Icon update complete!"
echo
echo "The new icon has been applied to:"
echo "- icon.iconset/ (all sizes)"
echo "- icon.icns (macOS icon bundle)"
echo "- AppIcon.png (main app icon)"
echo "- TaskNote Bridge.app (built application)"
echo
echo "You can now test the app to see the new icon!"
