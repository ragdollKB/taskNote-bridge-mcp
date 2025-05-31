# VS Code MCP Configuration for Things 3 Swift Server

## Prerequisites

1. Make sure you have the Things 3 app installed on macOS
2. Ensure the Swift MCP server files are in this directory
3. Have VS Code with MCP extension installed

## Setup Instructions

### 1. VS Code Settings

Add this configuration to your VS Code settings.json:

```json
{
  "mcp.servers": {
    "things-swift": {
      "command": "/Users/kb/things3-mcp-server/things-mcp/launch_swift_mcp_stdio.sh",
      "args": [],
      "env": {}
    }
  }
}
```

**Note**: Update the path `/Users/kb/things3-mcp-server/things-mcp/launch_swift_mcp_stdio.sh` to match your actual installation directory.

### 2. Alternative Configuration (Direct Swift)

If you prefer to call Swift directly:

```json
{
  "mcp.servers": {
    "things-swift": {
      "command": "swift",
      "args": ["/Users/kb/things3-mcp-server/things-mcp/swift_mcp_stdio.swift"],
      "env": {}
    }
  }
}
```

### 3. Claude Desktop Configuration

For Claude Desktop, add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "things-swift": {
      "command": "/Users/kb/things3-mcp-server/things-mcp/launch_swift_mcp_stdio.sh",
      "args": [],
      "env": {}
    }
  }
}
```

## Available Tools

### bb7_add-todo
Create a new task in Things 3

**Parameters:**
- `title` (required): The title of the task
- `notes` (optional): Additional notes for the task

**Example:**
```json
{
  "name": "bb7_add-todo",
  "arguments": {
    "title": "Review quarterly reports",
    "notes": "Focus on Q2 performance metrics and budget analysis"
  }
}
```

## Testing

You can test the server manually using:

```bash
cd /Users/kb/things3-mcp-server/things-mcp

# Test initialization
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | ./launch_swift_mcp_stdio.sh

# Test tools list
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | ./launch_swift_mcp_stdio.sh

# Test tool call
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"bb7_add-todo","arguments":{"title":"Test Task","notes":"This is a test"}}}' | ./launch_swift_mcp_stdio.sh
```

## Troubleshooting

1. **Permission Errors**: Make sure the script is executable:
   ```bash
   chmod +x /Users/kb/things3-mcp-server/things-mcp/launch_swift_mcp_stdio.sh
   ```

2. **Swift Not Found**: Ensure Swift is installed and in your PATH:
   ```bash
   which swift
   ```

3. **Things 3 Not Opening**: Verify Things 3 is installed and can be opened via URL scheme:
   ```bash
   open "things:///add?title=Test"
   ```

4. **VS Code MCP Extension**: Make sure you have an MCP-compatible extension installed in VS Code

## Server Features

- ✅ JSON-RPC 2.0 compliance
- ✅ stdio transport for VS Code compatibility  
- ✅ Things 3 integration via URL schemes
- ✅ Error handling and logging
- ✅ Task creation with title and notes
- ✅ Graceful shutdown handling

## Development

The server is implemented in Swift and located in:
- `swift_mcp_stdio.swift` - Main stdio server implementation
- `launch_swift_mcp_stdio.sh` - Launch wrapper script

For development and debugging, check the system logs:
```bash
log stream --predicate 'subsystem == "things-mcp-cli"' --level debug
```
