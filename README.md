# TaskNote Bridge - Swift MCP Server with Things 3 & Apple Notes ✅

[![Download Latest Release](https://img.shields.io/github/v/release/yourusername/tasknote-bridge?label=Download&style=for-the-badge)](https://github.com/yourusername/tasknote-bridge/releases/latest)

A native macOS Swift application that implements a complete [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) server for Things 3 and Apple Notes integration.

**Status**: ✅ **PRODUCTION READY** - Complete MCP server with GUI monitoring

<a href="https://glama.ai/mcp/servers/t9cgixg2ah"><img width="380" height="200" src="https://glama.ai/mcp/servers/t9cgixg2ah/badge" alt="Things Server MCP server" /></a>

## 🚀 **Quick Install**

### 📥 Download & Install
1. **[Download the latest release](https://github.com/yourusername/tasknote-bridge/releases/latest)**
2. **Open the DMG** and drag TaskNote Bridge to Applications
3. **Launch the app** - the MCP server starts automatically
4. **Configure VS Code** with the settings below

### ⚙️ VS Code Configuration
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

**That's it!** 🎉 You're ready to create tasks and notes via AI assistants.

## 📋 Requirements

- **macOS**: 12.0+ (Monterey or later)
- **Things 3**: Install from Mac App Store
- **Apple Notes**: Built into macOS
- **VS Code**: With MCP extension

## 🎯 **What Works Right Now**
```bash
# Test the stdio server (creates task in Things 3!)
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "bb7_add-todo", "arguments": {"title": "Hello from VS Code!", "tags": ["test"]}}}' | ./launch_swift_mcp_stdio.sh

# Expected output:
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"✅ Task 'Hello from VS Code!' created in Things 3","type":"text"}],"isError":false}}

# ✅ Check Things 3 - your task will be there!
```

### For GUI Monitoring
```bash
# Build and run the macOS app
xcodebuild -project "TaskNote Bridge.xcodeproj" -scheme "TaskNote Bridge" build
open "TaskNote Bridge.app"
# Server auto-starts with monitoring interface
```

## 🛠 **Complete Feature Set**

### Native macOS MCP Server Application
- **Complete MCP Server**: Full Swift implementation of MCP protocol with Things 3 and Apple Notes tools
- **Real-time Monitoring**: Server status dashboard with live activity tracking
- **TCP Transport**: Network-based transport protocol for universal MCP client compatibility
- **Log Streaming**: Live server logs with filtering and search capabilities
- **Connection Management**: Monitor active client connections and request/response activity
- **SwiftUI Interface**: Modern macOS interface for server monitoring and control

### Things 3 Integration
- Access to all major Things lists (Inbox, Today, Upcoming, etc.)
- Project and area management
- Tag operations
- Advanced search capabilities
- Recent items tracking
- Detailed item information including checklists
- Support for nested data (projects within areas, todos within projects)
- Open specific tasks directly in Things 3 app

### Apple Notes Integration
- Create new notes with titles, content, and tags
- Search notes by title
- Retrieve note content
- List all notes
- Open notes directly in Apple Notes app
- Delete notes
- Full AppleScript integration for seamless macOS experience

## Installation

### Option 1: Download the App (Recommended)
Download the latest `TaskNote Bridge.app` from the [Releases](https://github.com/yourusername/tasknote-bridge/releases) page

### Option 2: Build from Source
If you prefer to build from source, you'll need:
- Xcode 14.0 or newer
- macOS 13.0 or newer

Clone the repository and build:
```bash
# Clone the repository
git clone https://github.com/yourusername/things-mcp.git
cd things-mcp

# Open in Xcode and build
open "TaskNote Bridge.xcodeproj"
```

### Configuration

#### Prerequisites
* Any MCP-compatible AI assistant or tool (Claude Desktop, VS Code with MCP extensions, Cursor, Continue, Zed, etc.)
* Things 3 ("Enable Things URLs" must be turned on in Settings -> General)
* Apple Notes (for note management features)
* macOS 13.0 or newer (required for SwiftUI and AppleScript integration)

## 🔗 MCP Client Connection Guide

TaskNote Bridge supports multiple connection methods to work with various MCP clients. Choose the method that works best for your client:

### 🎯 Claude Desktop

#### Method 1: TCP Connection (Recommended)
1. **Launch TaskNote Bridge** app from Applications
2. **Start the TCP server** (default port 8000) - the app will show server status
3. **Configure Claude Desktop**:
   - Open Claude Desktop
   - Click the settings gear (⚙️) in the bottom left
   - Select "Developer"
   - In the "MCP Servers" section, click "Edit Config"
   - Add this configuration:

```json
{
    "mcpServers": {
        "tasknote-bridge": {
            "command": "nc",
            "args": ["localhost", "8000"]
        }
    }
}
```

4. **Restart Claude Desktop** to apply the changes

#### Method 2: Stdio Connection
1. **Configure Claude Desktop** with this settings:

```json
{
    "mcpServers": {
        "tasknote-bridge": {
            "command": "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh",
            "args": []
        }
    }
}
```

2. **Restart Claude Desktop**

> **💡 Tip**: Use Method 1 (TCP) if you want to keep the TaskNote Bridge monitoring interface open while using Claude Desktop.

### 🔧 VS Code with MCP Extension

1. **Install the MCP extension** for VS Code:
   - Open VS Code Extensions (Cmd+Shift+X)
   - Search for "Model Context Protocol" and install

2. **Configure VS Code** settings (`settings.json`):

```json
{
    "mcp": {
        "servers": {
            "tasknote-bridge": {
                "command": "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh",
                "args": []
            }
        }
    }
}
```

3. **Restart VS Code** to load the MCP server

### 🖱️ Cursor IDE

1. **Open Cursor Settings** (Cmd+,)
2. **Navigate to Extensions** → Model Context Protocol
3. **Add server configuration**:

```json
{
    "command": "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh",
    "args": []
}
```

### ⚡ Continue (VS Code Extension)

1. **Install Continue extension** in VS Code
2. **Open Continue config** (usually `~/.continue/config.json`)
3. **Add MCP server**:

```json
{
    "mcpServers": [
        {
            "name": "tasknote-bridge",
            "command": "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh",
            "args": []
        }
    ]
}
```

### 🚀 Zed Editor

1. **Open Zed Settings** (Cmd+,)
2. **Add to your settings.json**:

```json
{
    "assistant": {
        "mcp_servers": {
            "tasknote-bridge": {
                "command": "/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh"
            }
        }
    }
}
```

### 🛠️ Custom MCP Clients

For any custom MCP client or application:

#### TCP Connection
- **Host**: `localhost`
- **Port**: `8000` (default, configurable in TaskNote Bridge app)
- **Protocol**: TCP with JSON-RPC 2.0

#### Stdio Connection
- **Command**: `/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh`
- **Transport**: Standard input/output with JSON-RPC 2.0

### 📋 Verification Steps

After configuring any client:

1. **Test connection**:
   ```bash
   # For stdio testing
   echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | /Applications/TaskNote\ Bridge.app/Contents/Resources/launch_mcp_server.sh
   
   # For TCP testing (if server is running)
   echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | nc localhost 8000
   ```

2. **Check for available tools** - you should see tools like:
   - `bb7_add-todo`
   - `bb7_add-project`
   - `bb7_get-today`
   - `bb7_notes-create`
   - And many more...

3. **Test task creation**:
   ```bash
   echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "bb7_add-todo", "arguments": {"title": "Test from MCP!", "tags": ["test"]}}}' | /Applications/TaskNote\ Bridge.app/Contents/Resources/launch_mcp_server.sh
   ```

4. **Verify in Things 3** - the test task should appear in your Inbox

### 🔍 Troubleshooting Connection Issues

#### Claude Desktop Not Connecting
- Check that the config file is valid JSON
- Verify the file path exists: `/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh`
- Restart Claude Desktop completely
- Check Claude logs: `~/Library/Logs/Claude/mcp*.log`

#### TCP Connection Issues
- Ensure TaskNote Bridge app is running
- Check if port 8000 is available: `lsof -i :8000`
- Try a different port in TaskNote Bridge settings
- Verify firewall settings allow local connections

#### Stdio Connection Issues
- Verify script permissions: `ls -la /Applications/TaskNote\ Bridge.app/Contents/Resources/launch_mcp_server.sh`
- Test script directly in terminal
- Check that Things 3 URLs are enabled in Things 3 → Settings → General

#### For VS Code (with MCP extension)

1. First, ensure you have the TaskNote Bridge app installed and running.

2. Install the MCP extension for VS Code:
   - Open VS Code
   - Go to Extensions (Cmd+Shift+X)
   - Search for "MCP" and install the official MCP extension

3. Configure VS Code settings:
   - Open Settings (Cmd+,)
   - Click "Open Settings (JSON)" in the top right
   - Add this configuration:

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

> **Note**: Replace the path with the actual location where you installed the app. If you moved it to your Applications folder, use: `/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh`

4. Restart VS Code to load the MCP server.

### Usage 

### Usage 

#### In the TaskNote Bridge App

1. Launch the TaskNote Bridge app from your Applications folder.
2. The app provides a native macOS interface for:
   - Viewing your Things 3 tasks, projects, and areas
   - Managing your Apple Notes
   - Monitoring MCP server connections
   - Seeing activity logs in real-time

#### In Claude Desktop

Once connected, you can interact with TaskNote Bridge using natural language:

**Things 3 Examples:**
- "What's on my todo list today?"
- "Create a todo to pack for my beach vacation next week"
- "Create a project for Memorial Day BBQ with planning tasks"
- "Show me all my work-related tasks"
- "Mark the grocery shopping task as completed"
- "Add a task to call mom tomorrow"

**Apple Notes Examples:**
- "Create a note with meeting minutes from today's standup"
- "Search my notes for anything about the quarterly review"
- "Make a note about the new restaurant I want to try"
- "Show me all my notes with travel information"

#### In VS Code

With the MCP extension installed and configured:
1. Open the Command Palette (Cmd+Shift+P)
2. Type "MCP" to see available MCP commands
3. Use "MCP: Call Tool" to interact with Things tools
4. Or use any AI assistant that supports MCP to access your Things data

### For Any MCP-Compatible Tool

This server follows the standard MCP protocol and can work with any MCP-compatible application or AI assistant. Simply configure your tool to connect to the Swift MCP server using one of the methods above.

**Compatible Applications Include:**
- Claude Desktop
- VS Code with MCP extensions
- Cursor
- Continue
- Zed
- Sourcegraph Cody
- Any custom MCP client implementation

### 💡 Pro Tips for Better Integration

#### Claude Desktop Optimization
* **Create a custom project** in Claude with instructions about how you use Things 3 and organize areas, projects, tags, etc.
* **Tell Claude what information to include** when creating tasks (e.g., relevant details in task descriptions)
* **Combine with calendar MCP servers** to let Claude block time for tasks and create todos from calendar events

#### Multi-Client Usage
* **Use TCP mode** to connect multiple clients simultaneously
* **Keep TaskNote Bridge app open** to monitor all MCP activity in real-time
* **Check the app logs** if you encounter any issues with tool calls

#### Advanced Workflows
* "Evaluate my current todos using the Eisenhower matrix"
* "Help me conduct a GTD-style weekly review using Things"
* "Create a project plan for [project name] with subtasks and deadlines"
* "Analyze my task completion patterns and suggest improvements"


## Project Structure

```
TaskNote Bridge.app/          # The macOS Swift application
├── Contents/
│   ├── MacOS/                # Native Swift executable containing MCP server
│   │   └── TaskNote Bridge   # Main app with embedded MCP server
│   ├── Resources/            # Application resources
│   └── Info.plist            # App bundle configuration
├── TaskNote Bridge.xcodeproj/ # Xcode project
├── SwiftMCPServer.swift      # Core MCP server implementation
├── ThingsIntegration.swift   # Things 3 integration layer
├── NotesIntegration.swift    # Apple Notes integration layer
└── README.md                 # This documentation
```

### Available Tools

#### List Views
- `get-inbox` - Get todos from Inbox
- `get-today` - Get todos due today
- `get-upcoming` - Get upcoming todos
- `get-anytime` - Get todos from Anytime list
- `get-someday` - Get todos from Someday list
- `get-logbook` - Get completed todos
- `get-trash` - Get trashed todos

#### Basic Operations
- `get-todos` - Get todos, optionally filtered by project
- `get-projects` - Get all projects
- `get-areas` - Get all areas

#### Tag Operations
- `get-tags` - Get all tags
- `get-tagged-items` - Get items with a specific tag

#### Search Operations
- `search-todos` - Simple search by title/notes
- `search-advanced` - Advanced search with multiple filters
- `open-todo` - Search for a todo by title and open it in Things app

#### Time-based Operations
- `get-recent` - Get recently created items

## Tool Parameters

### get-todos
- `project_uuid` (optional) - Filter todos by project
- `include_items` (optional, default: true) - Include checklist items

### get-projects / get-areas / get-tags
- `include_items` (optional, default: false) - Include contained items

### search-advanced
- `status` - Filter by status (incomplete/completed/canceled)
- `start_date` - Filter by start date (YYYY-MM-DD)
- `deadline` - Filter by deadline (YYYY-MM-DD)
- `tag` - Filter by tag
- `area` - Filter by area UUID
- `type` - Filter by item type (to-do/project/heading)

### get-recent
- `period` - Time period (e.g., '3d', '1w', '2m', '1y')

### open-todo
- `title` - Title or partial title of the todo to search for and open

### notes-open
- `title` - Exact title of the note to open in Apple Notes


## Troubleshooting

### Connection Issues

#### Claude Desktop
- **Check config file**: Ensure the JSON configuration is valid and properly formatted
- **Verify file paths**: Make sure `/Applications/TaskNote Bridge.app/Contents/Resources/launch_mcp_server.sh` exists
- **Restart Claude**: Completely quit and restart Claude Desktop after configuration changes
- **Check logs**: Review Claude logs at `~/Library/Logs/Claude/mcp*.log`

#### TCP Connection Problems
- **App running**: Ensure TaskNote Bridge app is running with TCP server started
- **Port availability**: Check if port 8000 is available with `lsof -i :8000`
- **Firewall settings**: Verify macOS firewall allows local connections
- **Try different port**: Change port in TaskNote Bridge app settings if needed

#### Stdio Connection Issues
- **Script permissions**: Verify script is executable: `ls -la /Applications/TaskNote\ Bridge.app/Contents/Resources/launch_mcp_server.sh`
- **Direct testing**: Test the script in Terminal to ensure it works
- **Things 3 URLs**: Ensure "Enable Things URLs" is turned on in Things 3 → Settings → General

### Tool Execution Issues

The server includes comprehensive error handling for:
- Invalid UUIDs and malformed requests
- Missing required parameters
- Things 3 database access errors
- Apple Notes AppleScript execution errors
- Data formatting and serialization errors

All errors are logged with descriptive messages. To review MCP logs:

```bash
# Follow Claude Desktop logs in real-time
tail -n 20 -f ~/Library/Logs/Claude/mcp*.log

# Check TaskNote Bridge app logs
# Open TaskNote Bridge app and view the built-in log viewer

# Test server directly
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | /Applications/TaskNote\ Bridge.app/Contents/Resources/launch_mcp_server.sh
```

### Common Error Solutions

#### "Permission denied" errors
- Run: `chmod +x /Applications/TaskNote\ Bridge.app/Contents/Resources/launch_mcp_server.sh`
- Grant necessary permissions to TaskNote Bridge app in System Preferences → Security & Privacy

#### "Things 3 not responding" errors
- Ensure Things 3 is installed and has been launched at least once
- Check that "Enable Things URLs" is enabled in Things 3 settings
- Try restarting Things 3

#### "Apple Notes access denied" errors
- Grant TaskNote Bridge permission to control Apple Notes in System Preferences → Security & Privacy → Automation
- Ensure Apple Notes app is not restricted by any security software
