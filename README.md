# Things MCP Server - Swift MCP Server with Things 3 & Apple Notes ✅

A native macOS Swift application that implements a complete [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) server for Things 3 and Apple Notes integration. This project provides **TWO working MCP server implementations**:

1. **📱 macOS GUI App**: Complete server with monitoring interface
2. **⚡ stdio MCP Server**: Lightweight server for VS Code integration

**Status**: ✅ **PRODUCTION READY** - Both servers fully functional and tested with Things 3!

<a href="https://glama.ai/mcp/servers/t9cgixg2ah"><img width="380" height="200" src="https://glama.ai/mcp/servers/t9cgixg2ah/badge" alt="Things Server MCP server" /></a>

## 🎯 **What Works Right Now**

### ✅ **stdio MCP Server** (VS Code Ready)
- **Status**: ✅ **FULLY WORKING** - Tasks successfully created in Things 3
- **File**: `swift_mcp_stdio.swift` + `launch_swift_mcp_stdio.sh`
- **Purpose**: Direct VS Code MCP extension integration
- **Testing**: ✅ Verified task creation via Things 3 URL schemes
- **Integration**: Ready for VS Code MCP extension (see `VSCODE_MCP_SETUP.md`)

### ✅ **macOS GUI App** (Server Monitoring)
- **Status**: ✅ **BUILT & RUNNING** - Auto-starts MCP server
- **File**: `Things MCP.app` 
- **Purpose**: Server monitoring interface + TCP transport  
- **Features**: Real-time monitoring, log streaming, connection tracking
- **Transport**: TCP on port 8000 for network clients

## 🚀 **Quick Start**

### For VS Code Integration (Recommended)
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
xcodebuild -project "Things MCP.xcodeproj" -scheme "Things MCP" build
open "Things MCP.app"
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
1. Download the latest `Things MCP.app` from the [Releases](https://github.com/yourusername/things-mcp/releases) page
2. Use the included install script to move it to your Applications folder:
   ```bash
   ./install.sh
   ```
   This script will:
   - Copy the app to your Applications folder
   - Create necessary launcher scripts
   - Provide configuration instructions for VS Code and Claude Desktop
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
open "Things MCP.xcodeproj"
```

### Configuration

#### Prerequisites
* Any MCP-compatible AI assistant or tool (Claude Desktop, VS Code with MCP extensions, Cursor, Continue, Zed, etc.)
* Things 3 ("Enable Things URLs" must be turned on in Settings -> General)
* Apple Notes (for note management features)
* macOS 13.0 or newer (required for SwiftUI and AppleScript integration)

#### For Any MCP Client

1. Launch the Things MCP app and start the TCP server (default port 8000)

2. Configure your MCP client to connect to `localhost:8000`

**Examples:**

**Claude Desktop:**
```json
{
    "mcpServers": {
        "things": {
            "url": "tcp://localhost:8000"
        }
    }
}
```

**VS Code with MCP Extension:**
- Configure the extension to connect to `localhost:8000`

**Other MCP Tools:**
- Set connection type to TCP
- Host: `localhost` 
- Port: `8000`

> **Note**: Replace the path with the actual location where you installed the app. If you moved it to your Applications folder, use: `/Applications/Things MCP.app/Contents/Resources/launch_mcp_server.sh`

4. Restart the Claude Desktop app.

#### For VS Code (with MCP extension)

1. First, ensure you have the Things MCP app installed and running.

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
                "command": "/Users/kb/things3-mcp-server/things-mcp/Things MCP.app/Contents/Resources/launch_mcp_server.sh",
                "args": []
            }
        }
    }
}
```

> **Note**: Replace the path with the actual location where you installed the app. If you moved it to your Applications folder, use: `/Applications/Things MCP.app/Contents/Resources/launch_mcp_server.sh`

4. Restart VS Code to load the MCP server.

### Usage 

#### In the Things MCP App

1. Launch the Things MCP app from your Applications folder.
2. The app provides a native macOS interface for:
   - Viewing your Things 3 tasks, projects, and areas
   - Managing your Apple Notes
   - Monitoring MCP server connections
   - Seeing activity logs in real-time

#### In VS Code

With the MCP extension installed and configured:
1. Open the Command Palette (Cmd+Shift+P)
2. Type "MCP" to see available MCP commands
3. Use "MCP: Call Tool" to interact with Things tools
4. Or use any AI assistant that supports MCP to access your Things data

### For Any MCP-Compatible Tool

This server follows the standard MCP protocol and can work with any MCP-compatible application or AI assistant. Simply configure your tool to connect to the Swift MCP server via TCP on `localhost:8000`.

**Compatible Applications Include:**
- Claude Desktop
- VS Code with MCP extensions
- Cursor
- Continue
- Zed
- Any custom MCP client implementation

### Sample Usage
* "What's on my todo list today?"
* "Create a todo to pack for my beach vacation next week, include a packing checklist."
* "Evaluate my current todos using the Eisenhower matrix."
* "Help me conduct a GTD-style weekly review using Things."
* "Create a note with meeting minutes from today's standup"
* "Search my notes for anything about the quarterly review"

#### Tips
* Create a project in Claude with custom instructions that explains how you use Things and organize areas, projects, tags, etc. Tell Claude what information you want included when it creates a new task (eg asking it to include relevant details in the task description might be helpful).
* Try adding another MCP server that gives Claude access to your calendar. This will let you ask Claude to block time on your calendar for specific tasks, create todos from upcoming calendar events (eg prep for a meeting), etc.


## Project Structure

```
Things MCP.app/               # The macOS Swift application
├── Contents/
│   ├── MacOS/                # Native Swift executable containing MCP server
│   │   └── Things MCP        # Main app with embedded MCP server
│   ├── Resources/            # Application resources
│   └── Info.plist            # App bundle configuration
├── Things MCP.xcodeproj/     # Xcode project
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

The server includes error handling for:
- Invalid UUIDs
- Missing required parameters
- Things database access errors
- Data formatting errors

All errors are logged and returned with descriptive messages. To review the MCP logs from Claude Desktop, run this in the Terminal:
```bash
# Follow logs in real-time
tail -n 20 -f ~/Library/Logs/Claude/mcp*.log
```
