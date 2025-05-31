Remember here is how you do a build of the xcode project:

xcodebuild -project "/Users/kb/things3-mcp-server/things-m
cp/Things MCP.xcodeproj" -scheme "Things MCP" clean build


Every time you do a build and it fails, track that in a md file called isses.md and update that when the error is resolved. 

# GitHub Copilot Instructions for MCP Development

## Overview
This repository contains a macOS Swift application that implements a complete MCP (Model Context Protocol) server with Things 3 and Apple Notes integration capabilities.

## Project Structure

### macOS Swift MCP Server Application
The Swift macOS app (`Things MCP.xcodeproj`) is a **complete MCP server application** that:
- **Implements a full MCP server in Swift** with Things 3 and Apple Notes tools
- **Supports TCP transport protocol** for universal MCP client connections

**Important**: This is a self-contained MCP server application that implements the MCP protocol.

## Instruction Files Structure

### Core MCP Documentation
- [MCP Architecture & Concepts](./mcp-architecture.md) - Core MCP concepts, architecture, and protocol overview
- [MCP Client Implementation](./mcp-client-implementation.md) - Guidelines for implementing MCP clients
- [MCP Server Development](./mcp-server-development.md) - Best practices for MCP server development
- [MCP Protocol Specifications](./mcp-protocol-specs.md) - Detailed protocol specifications and technical implementation

### Project-Specific Usage
- [Things MCP Server Usage](./things-mcp-usage.md) - Instructions for using the Swift MCP server tools

## macOS App Purpose and Functionality

The Swift macOS application serves as a **complete MCP server with monitoring interface** with these features:

### Primary Functions
- **MCP Server Implementation**: Complete Swift-based MCP server with Things 3 and Apple Notes tools
- **Server Status Monitoring**: Real-time status display and server metrics
- **Log Streaming**: Live display of server logs and activity
- **Connection Management**: Handle TCP client connections from any MCP-compatible application
- **Request/Response Tracking**: Monitor MCP protocol communications
- **Performance Metrics**: Uptime, request counts, error rates

### UI Components
- **Status Dashboard**: Server state, uptime, connection count
- **Log Viewer**: Real-time scrolling log display with filtering
- **Connection Monitor**: Active client connections and transport types
- **Settings Panel**: Server configuration (ports, log levels, etc.)

**The app implements the MCP server directly in Swift - it IS the server, not just a monitor. It also is not a note taking or todo app, but rather a robust server application.**

## Key MCP Concepts

### What is MCP?
The Model Context Protocol (MCP) is an open standard for connecting AI assistants to external data sources and tools. It provides a standardized way for AI models to:
- Access real-time data
- Execute actions in external systems
- Maintain context across interactions
- Integrate with various applications and services

### MCP Architecture
- **Clients**: AI applications and tools (Claude Desktop, VS Code, Cursor, Continue, Zed, etc.)
- **Servers**: Applications that expose data and functionality via MCP (the Swift macOS app in this project)
- **Transport**: Communication layer (TCP over network)
- **Protocol**: JSON-RPC based messaging format

## Development Guidelines

When working with MCP:

1. **Follow Protocol Standards**: Use JSON-RPC 2.0 format for all communications
2. **Implement Proper Error Handling**: Handle connection failures and protocol errors gracefully
3. **Use Semantic Versioning**: Follow semantic versioning for server capabilities
4. **Document Tools Clearly**: Provide comprehensive tool descriptions and parameter schemas
5. **Test Thoroughly**: Test with multiple MCP clients for compatibility

### Swift Development (for the Monitor App)
For the Swift macOS monitoring application, follow these guidelines:

1. **Swift API Design Guidelines**: Follow official Swift.org naming conventions and API design principles
2. **Clarity at Point of Use**: Prioritize clear, unambiguous code over brevity
3. **Type Safety**: Leverage Swift's strong type system to prevent runtime errors
4. **Protocol-Oriented Programming**: Use protocols and extensions for composable behavior
5. **Memory Safety**: Use Swift's automatic memory management with weak/unowned references appropriately
6. **Concurrency**: Use actors and async/await for thread-safe concurrent operations
7. **Error Handling**: Use Swift's error handling system with throwing functions and Result types
8. **UI Responsiveness**: Keep monitoring tasks on background queues to maintain UI responsiveness
9. **Real-time Updates**: Use Combine or async streams for real-time log and status updates

**For comprehensive Swift guidelines, see [Swift Coding Instructions](./swift-coding-instructions.md)**

## macOS App Development Focus

When working on the Swift macOS application:

### Primary Goals
- **Server Implementation**: Implement the core MCP server functionality in Swift
- **Status Monitoring**: Monitor the app's own MCP server health and status
- **Log Management**: Display, filter, and manage server logs effectively
- **Connection Tracking**: Show active client connections and transport types
- **Administrative Controls**: Provide server start/stop and configuration capabilities

### Avoid These Patterns
- **Direct Task Management**: Don't implement Things 3 task creation in the UI
- **Note Management**: Don't implement Apple Notes functionality in the UI
- **Business Logic**: Keep the UI focused on monitoring, not domain-specific functionality

### Implementation Patterns
- **Real-time Updates**: Use publishers/subscribers for live data
- **Log Streaming**: Display structured log output in real-time
- **Network Monitoring**: Track TCP connections
- **MCP Protocol**: Implement complete MCP server in Swift

## Security Considerations

- Validate all inputs from MCP clients
- Implement proper authentication when needed
- Use HTTPS for HTTP-based transports
- Follow principle of least privilege for tool access
- Log security-relevant events

---

For detailed implementation guidance, refer to the specific instruction files listed above.
