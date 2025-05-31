# VS Code MCP Configuration for TaskNote Bridge

## Prerequisites

1. Make sure you have **Things 3** and **Apple Notes** installed on macOS
2. Have VS Code with an MCP extension installed
3. TaskNote Bridge.app available in your project directory

## Setup Instructions

### VS Code Settings Configuration

Add this configuration to your VS Code settings.json:

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

**Note**: Update the path to match your actual TaskNote Bridge app location if different.

## Available Tools

### Things 3 Tools

#### bb7_add-todo
Create a new task in Things 3

**Parameters:**
- `title` (required): The title of the task
- `notes` (optional): Additional notes for the task
- `deadline` (optional): Due date in YYYY-MM-DD format
- `tags` (optional): Array of tag strings
- `when` (optional): Schedule ("today", "tomorrow", "evening", "anytime", "someday", or YYYY-MM-DD)

#### bb7_add-project
Create a new project in Things 3

**Parameters:**
- `title` (required): The title of the project
- `notes` (optional): Additional notes
- `todos` (optional): Array of initial tasks to create

#### bb7_search-todos
Search for existing tasks

**Parameters:**
- `query` (required): Search term

### Apple Notes Tools

#### bb7_notes-create
Create a new note in Apple Notes

**Parameters:**
- `title` (required): The title of the note
- `content` (required): The content of the note
- `tags` (optional): Array of tag strings

#### bb7_notes-search
Search for notes by title

**Parameters:**
- `query` (required): Search term

#### bb7_notes-list
List all notes in Apple Notes

**Example Usage:**
```json
{
  "name": "bb7_add-todo",
  "arguments": {
    "title": "Review quarterly reports",
    "notes": "Focus on Q2 performance metrics and budget analysis",
    "deadline": "2025-06-15",
    "tags": ["work", "quarterly"]
  }
}
```

## Testing

You can test the server manually using:

```bash
cd /path/to/your/project

# Test initialization
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | ./launch_swift_mcp_stdio.sh

# Test tools list
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | ./launch_swift_mcp_stdio.sh

# Test Things 3 task creation
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"bb7_add-todo","arguments":{"title":"Test Task","notes":"This is a test"}}}' | ./launch_swift_mcp_stdio.sh

# Test Apple Notes creation
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"bb7_notes-create","arguments":{"title":"Test Note","content":"This is a test note"}}}' | ./launch_swift_mcp_stdio.sh
```

## Troubleshooting

1. **Permission Errors**: Make sure the script is executable:
   ```bash
   chmod +x /path/to/your/project/launch_swift_mcp_stdio.sh
   ```

2. **Swift Not Found**: Ensure Swift is installed and in your PATH:
   ```bash
   which swift
   ```

3. **Things 3 Not Opening**: Verify Things 3 is installed and can be opened via URL scheme:
   ```bash
   open "things:///add?title=Test"
   ```

4. **Apple Notes Not Working**: Verify Apple Notes access:
   ```bash
   osascript -e 'tell application "Notes" to make new note with properties {body:"Test"}'
   ```

5. **VS Code MCP Extension**: Make sure you have an MCP-compatible extension installed in VS Code

## Server Features

- ✅ JSON-RPC 2.0 compliance
- ✅ stdio transport for VS Code compatibility  
- ✅ Things 3 integration via URL schemes
- ✅ Apple Notes integration via AppleScript
- ✅ Error handling and logging
- ✅ Task and project creation with rich metadata
- ✅ Note creation and management
- ✅ Search functionality for both platforms
- ✅ Graceful shutdown handling

## Development

The server is implemented in Swift and located in:
- `swift_mcp_stdio.swift` - Main stdio server implementation
- `launch_swift_mcp_stdio.sh` - Launch wrapper script
- `TaskNote Bridge.app` - Complete macOS app with GUI monitoring

For development and debugging, check the system logs:
```bash
log stream --predicate 'subsystem == "taskNote-bridge"' --level debug
```
