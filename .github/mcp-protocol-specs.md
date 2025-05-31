# MCP Protocol Specifications

## Protocol Overview

The Model Context Protocol (MCP) is based on JSON-RPC 2.0 and provides a standardized way for AI applications to communicate with external data sources and tools.

## JSON-RPC 2.0 Foundation

### Request Format
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "search_files",
    "arguments": {
      "pattern": "*.py"
    }
  }
}
```

### Response Format
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Found 5 Python files"
      }
    ]
  }
}
```

### Error Response
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "details": "Missing required parameter 'pattern'"
    }
  }
}
```

## Connection Lifecycle

### 1. Initialization
```json
// Client sends initialization request
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {},
      "resources": {},
      "prompts": {}
    },
    "clientInfo": {
      "name": "my-client",
      "version": "1.0.0"
    }
  }
}

// Server responds with capabilities
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {
        "listChanged": true
      },
      "resources": {
        "subscribe": true,
        "listChanged": true
      },
      "prompts": {
        "listChanged": true
      }
    },
    "serverInfo": {
      "name": "my-server",
      "version": "1.0.0"
    }
  }
}
```

### 2. Capability Negotiation
The initialization response establishes which features both client and server support:

- **tools**: Tool execution capabilities
- **resources**: Resource access capabilities  
- **prompts**: Prompt template capabilities
- **sampling**: Text generation capabilities

## Core Methods

### Tools

#### List Tools
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}

// Response
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      {
        "name": "search_files",
        "description": "Search for files matching a pattern",
        "inputSchema": {
          "type": "object",
          "properties": {
            "pattern": {
              "type": "string",
              "description": "File pattern to search for"
            },
            "directory": {
              "type": "string",
              "description": "Directory to search in",
              "default": "."
            }
          },
          "required": ["pattern"]
        }
      }
    ]
  }
}
```

#### Call Tool
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "search_files",
    "arguments": {
      "pattern": "*.py",
      "directory": "/src"
    }
  }
}

// Response
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Found 3 files:\n- main.py\n- utils.py\n- test.py"
      }
    ],
    "isError": false
  }
}
```

### Resources

#### List Resources
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "resources/list"
}

// Response
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "resources": [
      {
        "uri": "file:///config/app.json",
        "name": "Application Config",
        "description": "Main application configuration",
        "mimeType": "application/json"
      }
    ]
  }
}
```

#### Read Resource
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "resources/read",
  "params": {
    "uri": "file:///config/app.json"
  }
}

// Response
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "contents": [
      {
        "uri": "file:///config/app.json",
        "mimeType": "application/json",
        "text": "{\"debug\": true, \"port\": 8080}"
      }
    ]
  }
}
```

### Prompts

#### List Prompts
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "prompts/list"
}

// Response
{
  "jsonrpc": "2.0",
  "id": 6,
  "result": {
    "prompts": [
      {
        "name": "code_review",
        "description": "Review code for quality and issues",
        "arguments": [
          {
            "name": "language",
            "description": "Programming language",
            "required": true
          },
          {
            "name": "code",
            "description": "Code to review",
            "required": true
          }
        ]
      }
    ]
  }
}
```

#### Get Prompt
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "prompts/get",
  "params": {
    "name": "code_review",
    "arguments": {
      "language": "python",
      "code": "def hello():\n    print('Hello')"
    }
  }
}

// Response
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "description": "Code review for Python code",
    "messages": [
      {
        "role": "user",
        "content": {
          "type": "text",
          "text": "Please review this Python code:\n\ndef hello():\n    print('Hello')\n\nFocus on best practices and potential improvements."
        }
      }
    ]
  }
}
```

## Data Types

### Content Types
```json
// Text content
{
  "type": "text",
  "text": "Some text content"
}

// Image content  
{
  "type": "image",
  "data": "base64-encoded-image-data",
  "mimeType": "image/png"
}

// Resource reference
{
  "type": "resource",
  "resource": {
    "uri": "file:///path/to/file.txt",
    "text": "File contents...",
    "mimeType": "text/plain"
  }
}
```

### Tool Schema
```json
{
  "name": "create_task",
  "description": "Create a new task",
  "inputSchema": {
    "type": "object",
    "properties": {
      "title": {
        "type": "string",
        "description": "Task title"
      },
      "priority": {
        "type": "string",
        "enum": ["low", "medium", "high"],
        "default": "medium"
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Due date in YYYY-MM-DD format"
      }
    },
    "required": ["title"]
  }
}
```

## Notifications

### Resource Updates
```json
{
  "jsonrpc": "2.0",
  "method": "notifications/resources/updated",
  "params": {
    "uri": "file:///config/app.json"
  }
}
```

### Tool List Changes
```json
{
  "jsonrpc": "2.0",
  "method": "notifications/tools/list_changed"
}
```

## Error Codes

### Standard JSON-RPC Errors
- `-32700`: Parse error
- `-32600`: Invalid request
- `-32601`: Method not found
- `-32602`: Invalid params
- `-32603`: Internal error

### MCP-Specific Errors
- `-32000`: Server error (generic)
- `-32001`: Invalid tool name
- `-32002`: Invalid resource URI
- `-32003`: Resource not found
- `-32004`: Tool execution failed
- `-32005`: Permission denied

## Transport Mechanisms

### Standard I/O (stdio)
- Process-to-process communication
- Client launches server as subprocess
- Communication via stdin/stdout
- Simple and efficient for local use

### HTTP with Server-Sent Events
- Network-based communication
- RESTful HTTP endpoints for requests
- Server-Sent Events for notifications
- Suitable for remote/web deployments

### Transport Selection Guidelines
- **stdio**: Local applications, development tools
- **HTTP/SSE**: Web applications, remote servers, microservices

## Security Framework

### Authentication
```json
// Authorization header approach
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "secure_operation"
  },
  "_meta": {
    "authorization": "Bearer token123"
  }
}
```

### Permission Model
- Capability-based access control
- Granular permissions per tool/resource
- Runtime permission validation
- Audit trail for security events

### Input Sanitization
- Validate all input parameters
- Sanitize file paths and URIs
- Prevent injection attacks
- Implement rate limiting

## Best Practices

### Performance
- Implement connection pooling
- Use caching for frequently accessed resources
- Batch multiple operations when possible
- Implement proper timeout handling

### Error Handling
- Provide descriptive error messages
- Include context in error responses
- Log errors for debugging
- Implement graceful degradation

### Versioning
- Use semantic versioning
- Maintain backward compatibility
- Clearly document breaking changes
- Support multiple protocol versions

### Testing
- Unit test all methods
- Integration test client-server communication
- Test error conditions
- Validate schema compliance

This specification provides the technical foundation for implementing MCP-compliant clients and servers.
