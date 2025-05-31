# TaskNote Bridge Installation Guide

## Download and Install

### Step 1: Download
1. Go to the [latest release](https://github.com/yourusername/tasknote-bridge/releases/latest)
2. Download `TaskNote-Bridge-v1.0.0.dmg`

### Step 2: Install
1. **Open the DMG** - Double-click the downloaded file
2. **Drag to Applications** - Drag "TaskNote Bridge.app" to the Applications folder
3. **Eject the DMG** - Right-click the mounted disk and select "Eject"

### Step 3: First Launch
1. **Open the app** - Go to Applications and double-click "TaskNote Bridge"
2. **Security prompt** - If you see "App can't be opened", do this:
   - Go to System Preferences → Security & Privacy
   - Click "Open Anyway" next to the TaskNote Bridge message
   - Or right-click the app → "Open" → "Open" to bypass Gatekeeper

### Step 4: Verify Installation
- The app should open and show "MCP Server Running"
- The menu bar should show server status
- No additional configuration needed - the server starts automatically

## VS Code Setup

Add this to your VS Code `settings.json`:

```json
{
    "mcp": {
        "inputs": [],
        "servers": {
            "things-swift": {
                "command": "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh",
                "args": []
            }
        }
    }
}
```

## Requirements

- **macOS**: 12.0 (Monterey) or later
- **Things 3**: Install from Mac App Store (for task management)
- **Apple Notes**: Built into macOS (for note creation)
- **VS Code**: With MCP extension installed

## Troubleshooting

### "App is damaged and can't be opened"
This happens because the app isn't signed with an Apple Developer certificate.

**Solution**:
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine "/Applications/TaskNote Bridge.app"
```

### Permission Issues
If you get permission errors:
```bash
# Make launch script executable
chmod +x "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh"
```

### VS Code Can't Find Server
1. Verify the app is in `/Applications/`
2. Check the path in your VS Code settings
3. Restart VS Code after configuration changes

### Things 3 Integration Not Working
1. Make sure Things 3 is installed and opened at least once
2. Test the URL scheme: `open "things:///add?title=Test"`
3. Grant necessary permissions when prompted

### Apple Notes Integration Not Working
1. Open Apple Notes app once to initialize it
2. Grant permission when prompted for automation access

## Uninstall

To completely remove TaskNote Bridge:

1. **Quit the app** if running
2. **Delete the app**: Drag "TaskNote Bridge.app" from Applications to Trash
3. **Remove VS Code configuration**: Remove the MCP server entry from settings.json

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/tasknote-bridge/issues)
- **Documentation**: [Project README](https://github.com/yourusername/tasknote-bridge)
- **MCP Protocol**: [Model Context Protocol Docs](https://modelcontextprotocol.io)

## What's Included

- **TaskNote Bridge.app** - Complete MCP server with GUI monitoring
- **MCP Tools** - Things 3 and Apple Notes integration
- **Auto-start** - Server starts automatically when app launches
- **Real-time logs** - Monitor server activity and connections
- **VS Code ready** - Pre-configured for seamless integration
