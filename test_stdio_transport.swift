#!/usr/bin/env swift

import Foundation

/**
 * Test script for stdio transport mode of Swift MCP Server
 * This simulates how VS Code would interact with our server via stdin/stdout
 */

func testStdioTransport() {
    print("Testing Swift MCP Server stdio transport...")
    
    // Create a process to launch our Swift MCP server in stdio mode
    let process = Process()
    
    // Path to the built Swift app
    let appPath = "/Users/kb/things3-mcp-server/things-mcp/build/Debug/Things MCP.app/Contents/MacOS/Things MCP"
    
    process.executableURL = URL(fileURLWithPath: appPath)
    process.arguments = ["--stdio"] // Tell our app to use stdio mode
    
    // Set up pipes for communication
    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    
    process.standardInput = inputPipe
    process.standardOutput = outputPipe  
    process.standardError = errorPipe
    
    do {
        try process.run()
        
        // Give the server a moment to start
        Thread.sleep(forTimeInterval: 1.0)
        
        // Send MCP initialization request
        let initRequest = """
        {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}, "resources": {}, "prompts": {}}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}
        
        """
        
        inputPipe.fileHandleForWriting.write(Data(initRequest.utf8))
        
        // Read response
        let responseData = outputPipe.fileHandleForReading.availableData
        if let response = String(data: responseData, encoding: .utf8) {
            print("Server response:")
            print(response)
        }
        
        // Send tools/list request
        let toolsRequest = """
        {"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
        
        """
        
        inputPipe.fileHandleForWriting.write(Data(toolsRequest.utf8))
        
        // Read tools response
        Thread.sleep(forTimeInterval: 0.5)
        let toolsResponseData = outputPipe.fileHandleForReading.availableData
        if let toolsResponse = String(data: toolsResponseData, encoding: .utf8) {
            print("Tools response:")
            print(toolsResponse)
        }
        
        // Terminate the process
        process.terminate()
        process.waitUntilExit()
        
        print("Test completed.")
        
    } catch {
        print("Error running test: \(error)")
    }
}

// Check if the app exists first
let appPath = "/Users/kb/things3-mcp-server/things-mcp/build/Debug/Things MCP.app/Contents/MacOS/Things MCP"
if FileManager.default.fileExists(atPath: appPath) {
    print("Found Swift MCP app at: \(appPath)")
    testStdioTransport()
} else {
    print("Swift MCP app not found at: \(appPath)")
    print("Make sure to build the project first with: xcodebuild -project 'Things MCP.xcodeproj' -scheme 'Things MCP' build")
}
