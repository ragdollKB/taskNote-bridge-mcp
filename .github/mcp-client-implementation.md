# MCP Client Implementation Guide

## Overview

This guide covers implementing MCP clients that connect AI applications to MCP servers. MCP clients handle the protocol communication, connection management, and integration with host applications.

## Supported MCP Clients

### Desktop Applications
- **Claude Desktop**: Native desktop app by Anthropic
- **VSCode (via extensions)**: Multiple extensions supporting MCP
- **Cursor**: AI-powered code editor with built-in MCP support
- **Continue**: Open-source AI coding assistant
- **Zed**: Collaborative code editor
- **Sourcegraph Cody**: AI coding assistant
- **Windmill**: Workflow automation platform

### Command Line Tools
- **MCP Inspector**: Official debugging and testing tool
- **mcp-client-cli**: Command-line MCP client
- **Various custom CLI tools**: Community-built clients

### Web Applications
- **Replit Agent**: AI coding assistant in browser
- **StackBlitz**: Online IDE with AI features
- **GitHub Copilot Chat**: Web-based coding assistance

### Mobile Applications
- **Claude Mobile**: Anthropic's mobile app
- **Various community apps**: Third-party implementations

## Implementation Languages

### TypeScript/JavaScript
- **@modelcontextprotocol/sdk**: Official TypeScript SDK
- **Node.js support**: Server-side implementations
- **Browser compatibility**: Web-based clients
- **React integration**: UI component libraries

### Python
- **mcp package**: Official Python SDK
- **asyncio support**: Asynchronous operations
- **FastAPI integration**: Web server implementations
- **Jupyter support**: Notebook environments

### Rust
- **mcp-rs**: Rust implementation
- **High performance**: System-level applications
- **Memory safety**: Secure implementations
- **Cross-platform**: Desktop and embedded systems

### Java/Kotlin
- **mcp-java-sdk**: Official Java implementation
- **Spring Boot integration**: Enterprise applications
- **Android support**: Mobile implementations
- **Kotlin coroutines**: Asynchronous programming

### C#/.NET
- **MCP.NET**: Community implementation
- **ASP.NET Core**: Web applications
- **WPF/WinUI**: Desktop applications
- **Xamarin**: Mobile applications

### Swift
- **Native iOS/macOS support**: Native Apple platform integration
- **Actors and async/await**: Modern concurrency patterns
- **Foundation networking**: Native HTTP/URLSession support
- **Process management**: Native stdio transport support

## Core Client Features

### Connection Management
```typescript
import { Client, StdioClientTransport } from '@modelcontextprotocol/sdk/client/index.js';


// Create and connect client
const client = new Client({
  name: 'my-client',
  version: '1.0.0'
}, {
  capabilities: {
    tools: {},
    resources: {},
    prompts: {}
  }
});

await client.connect(transport);
```

### Swift Implementation Example
```swift
// Swift MCP Client Connection
class MCPClient {
    private let transport: MCPTransport
    private let capabilities: MCPCapabilities
    
    init(transport: MCPTransport, capabilities: MCPCapabilities) {
        self.transport = transport
        self.capabilities = capabilities
    }
    
    func connect() async throws {
        let initRequest = MCPInitializeRequest(
            protocolVersion: "2024-11-05",
            capabilities: capabilities,
            clientInfo: MCPClientInfo(name: "Swift-Client", version: "1.0.0")
        )
        
        let response = try await transport.send(initRequest)
        // Handle initialization response
    }
}
```

### Tool Discovery and Execution
```typescript
// List available tools
const tools = await client.listTools();

// Execute a tool
const result = await client.callTool({
  name: 'search_files',
  arguments: {
    pattern: '*.py',
    directory: '/src'
  }
});
```

### Swift Tool Execution
```swift
// Swift tool execution
func callTool(name: String, arguments: [String: Any]) async throws -> MCPToolResult {
    let request = MCPToolCallRequest(
        name: name,
        arguments: arguments
    )
    
    let response = try await transport.send(request) // Assuming transport can send MCPToolCallRequest
    // Need to define how MCPToolResult is created from a generic MCPResponse
    // This might involve checking response.result and decoding it specifically
    // For now, let's assume a direct conversion or a specific method on MCPResponse
    guard let toolResult = response.result as? [String: Any] else {
        // Or handle error if response.error is not nil
        if let error = response.error {
            throw MCPClientError.toolExecutionFailed(toolName: name, error: error.message)
        }
        throw MCPClientError.invalidResponse(details: "Failed to decode tool result")
    }
    return MCPToolResult(from: toolResult) // Assuming MCPToolResult has an initializer
}
```

### Resource Access
```typescript
// List available resources
const resources = await client.listResources();

// Read a resource
const content = await client.readResource({
  uri: 'file:///path/to/file.txt'
});
```

### Prompt Templates
```typescript
// List available prompts
const prompts = await client.listPrompts();

// Get a prompt template
const prompt = await client.getPrompt({
  name: 'code_review',
  arguments: {
    language: 'python',
    file_path: 'src/main.py'
  }
});
```

## Implementation Best Practices

### Error Handling
```typescript
try {
  const result = await client.callTool({
    name: 'risky_operation',
    arguments: { data: 'test' }
  });
} catch (error) {
  if (error instanceof McpError) {
    // Handle MCP-specific errors
    console.error('MCP Error:', error.code, error.message);
  } else {
    // Handle other errors
    console.error('Unexpected error:', error);
  }
}
```

### Connection Resilience
```typescript
class ResilientClient {
  private client: Client;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  async connect() {
    while (this.reconnectAttempts < this.maxReconnectAttempts) {
      try {
        await this.client.connect(transport);
        this.reconnectAttempts = 0;
        break;
      } catch (error) {
        this.reconnectAttempts++;
        await this.delay(1000 * this.reconnectAttempts);
      }
    }
  }

  private delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### Resource Caching
```typescript
class CachingClient {
  private cache = new Map<string, any>();
  private cacheTimeout = 5 * 60 * 1000; // 5 minutes

  async readResource(uri: string) {
    const cached = this.cache.get(uri);
    if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
      return cached.data;
    }

    const data = await this.client.readResource({ uri });
    this.cache.set(uri, {
      data,
      timestamp: Date.now()
    });

    return data;
  }
}
```

## Security Considerations

### Input Validation
```typescript
function validateToolArguments(args: any, schema: any): boolean {
  // Validate arguments against expected schema
  // Sanitize input data
  // Check for malicious content
  return true;
}

// Use before tool calls
if (!validateToolArguments(args, toolSchema)) {
  throw new Error('Invalid tool arguments');
}
```

### Access Control
```typescript
class SecureClient {
  private allowedTools = new Set(['safe_tool1', 'safe_tool2']);

  async callTool(request: CallToolRequest) {
    if (!this.allowedTools.has(request.name)) {
      throw new Error(`Tool '${request.name}' not allowed`);
    }

    return await this.client.callTool(request);
  }
}
```

### Credential Management
```typescript
// Use environment variables for credentials
const credentials = {
  token: process.env.MCP_TOKEN,
  apiKey: process.env.API_KEY
};

// Don't log sensitive information
const sanitizedArgs = { ...args };
delete sanitizedArgs.password;
console.log('Calling tool with args:', sanitizedArgs);
```

## Integration Patterns

### Host Application Integration
```typescript
// Plugin architecture for VS Code
export class McpExtension {
  private clients = new Map<string, Client>();

  async activate(context: vscode.ExtensionContext) {
    // Register MCP servers from configuration
    // VS Code's built-in MCP client primarily supports stdio, http, and sse transports.
    // Configuration is typically via a 'command' (for stdio) or 'url' (for http/sse).
    // Direct TCP configuration is not a standard supported method for the built-in client.
    const servers = vscode.workspace.getConfiguration('mcp.servers');
    
    for (const [name, config] of Object.entries(servers)) {
      await this.connectServer(name, config);
    }
  }

  async connectServer(name: string, config: any) {
    // Example: For stdio, config might contain { command: "path/to/server", args: ["--port", "1234"] }
    // Example: For http/sse, config might contain { url: "http://localhost:1234/mcp" }
    // The actual transport creation will depend on the config structure.
    const client = new Client(/* ... */);
    await client.connect(/* transport from config */);
    this.clients.set(name, client);
  }
}
```

### Command Processing
```typescript
// Natural language to MCP tool mapping
class CommandProcessor {
  async processCommand(input: string): Promise<any> {
    const intent = await this.parseIntent(input);
    
    switch (intent.action) {
      case 'create_task':
        return await this.client.callTool({
          name: 'add_todo',
          arguments: intent.parameters
        });
      
      case 'search_files':
        return await this.client.callTool({
          name: 'file_search',
          arguments: intent.parameters
        });
    }
  }
}
```

## Testing

### Unit Testing
```typescript
import { jest } from '@jest/globals';

describe('MCP Client', () => {
  let client: Client;
  let mockTransport: jest.Mocked<Transport>;

  beforeEach(() => {
    mockTransport = {
      send: jest.fn(),
      close: jest.fn()
    };
    client = new Client(config, capabilities);
  });

  test('should call tool successfully', async () => {
    mockTransport.send.mockResolvedValue({
      jsonrpc: '2.0',
      id: 1,
      result: { success: true }
    });

    const result = await client.callTool({
      name: 'test_tool',
      arguments: {}
    });

    expect(result.success).toBe(true);
  });
});
```

### Integration Testing
```typescript
describe('MCP Integration', () => {
  test('should connect to real server', async () => {
    const transport = new StdioClientTransport({
      command: 'python',
      args: ['test_server.py']
    });

    const client = new Client(config, capabilities);
    await client.connect(transport);

    const tools = await client.listTools();
    expect(tools.length).toBeGreaterThan(0);

    await client.close();
  });
});
```

## Performance Optimization

### Connection Pooling
```typescript
class ConnectionPool {
  private pools = new Map<string, Client[]>();
  private maxConnections = 5;

  async getClient(serverId: string): Promise<Client> {
    const pool = this.pools.get(serverId) || [];
    
    if (pool.length > 0) {
      return pool.pop()!;
    }

    if (pool.length < this.maxConnections) {
      return await this.createNewClient(serverId);
    }

    // Wait for available connection
    return await this.waitForAvailableClient(serverId);
  }
}
```

### Request Batching
```typescript
class BatchingClient {
  private pendingRequests: Array<{
    request: any;
    resolve: Function;
    reject: Function;
  }> = [];

  async callTool(request: CallToolRequest) {
    return new Promise((resolve, reject) => {
      this.pendingRequests.push({ request, resolve, reject });
      this.processBatch();
    });
  }

  private async processBatch() {
    if (this.pendingRequests.length === 0) return;

    const batch = this.pendingRequests.splice(0, 10);
    const requests = batch.map(item => item.request);

    try {
      const results = await this.client.batch(requests);
      batch.forEach((item, index) => {
        item.resolve(results[index]);
      });
    } catch (error) {
      batch.forEach(item => item.reject(error));
    }
  }
}
```

This guide provides a comprehensive foundation for implementing MCP clients across different platforms and use cases.
