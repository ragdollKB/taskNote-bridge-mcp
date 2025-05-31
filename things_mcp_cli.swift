#!/usr/bin/swift

//
//  Command-line MCP Server for VS Code stdio transport
//  This script runs the Swift MCP server in stdio mode for VS Code integration
//

import Foundation
import OSLog

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Shared Swift MCP Server Code
// Note: In a real implementation, this would import from the main module
// For now, we'll include a minimal version here

/// Transport mode for MCP server
enum MCPTransportMode {
    case stdio
}

/// Minimal MCP Server for stdio transport
@MainActor
class StdioMCPServer {
    
    private let logger = Logger(subsystem: "things-mcp-cli", category: "StdioMCPServer")
    private var stdioTask: Task<Void, Never>?
    private var isRunning = false
    
    init() {
        logger.info("StdioMCPServer initialized for command-line use")
    }
    
    func start() async {
        guard !isRunning else {
            logger.warning("Server already running")
            return
        }
        
        isRunning = true
        logger.info("Starting stdio MCP server...")
        
        // Start stdio server
        await startStdioServer()
    }
    
    func stop() {
        guard isRunning else { return }
        
        stdioTask?.cancel()
        stdioTask = nil
        isRunning = false
        
        logger.info("Stdio MCP server stopped")
    }
    
    private func startStdioServer() async {
        stdioTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.handleStdioInput()
                }
            }
        }
    }
    
    private func handleStdioInput() async {
        let inputHandle = FileHandle.standardInput
        let outputHandle = FileHandle.standardOutput
        
        logger.info("Stdio server started, waiting for input...")
        
        while !Task.isCancelled {
            do {
                if let line = await readLine(from: inputHandle) {
                    await processStdioData(line, outputHandle: outputHandle)
                } else {
                    // EOF reached
                    logger.info("EOF reached, shutting down")
                    break
                }
            } catch {
                logger.error("Error reading from stdin: \(error.localizedDescription)")
                break
            }
        }
    }
    
    private func readLine(from handle: FileHandle) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let data = handle.availableData
                if data.isEmpty {
                    continuation.resume(returning: nil)
                    return
                }
                
                if let line = String(data: data, encoding: .utf8) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        continuation.resume(returning: trimmed)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func processStdioData(_ data: String, outputHandle: FileHandle) async {
        logger.debug("Received data: \(data)")
        
        // Parse JSON-RPC
        guard let jsonData = data.data(using: .utf8) else {
            logger.error("Failed to convert input to UTF-8 data")
            return
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                logger.error("Failed to parse JSON")
                return
            }
            
            await handleMCPRequest(json, outputHandle: outputHandle)
            
        } catch {
            logger.error("JSON parsing error: \(error.localizedDescription)")
            await sendError(id: nil, code: -32700, message: "Parse error", outputHandle: outputHandle)
        }
    }
    
    private func handleMCPRequest(_ request: [String: Any], outputHandle: FileHandle) async {
        let method = request["method"] as? String ?? ""
        let id = request["id"]
        
        logger.info("Handling MCP request: \(method)")
        
        switch method {
        case "initialize":
            await handleInitialize(id: id, outputHandle: outputHandle)
        case "tools/list":
            await handleToolsList(id: id, outputHandle: outputHandle)
        case "tools/call":
            if let params = request["params"] as? [String: Any] {
                await handleToolCall(id: id, params: params, outputHandle: outputHandle)
            } else {
                await sendError(id: id, code: -32602, message: "Invalid params", outputHandle: outputHandle)
            }
        default:
            await sendError(id: id, code: -32601, message: "Method not found", outputHandle: outputHandle)
        }
    }
    
    private func handleInitialize(id: Any?, outputHandle: FileHandle) async {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [
                        "listChanged": true
                    ]
                ],
                "serverInfo": [
                    "name": "things-mcp-swift-cli",
                    "version": "1.0.0"
                ]
            ]
        ]
        
        await sendResponse(response, outputHandle: outputHandle)
    }
    
    private func handleToolsList(id: Any?, outputHandle: FileHandle) async {
        let tools = [
            [
                "name": "bb7_add-todo",
                "description": "Create a new task in Things 3",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "The title of the task"
                        ],
                        "notes": [
                            "type": "string",
                            "description": "Additional notes for the task"
                        ],
                        "tags": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Tags for the task"
                        ]
                    ],
                    "required": ["title"]
                ]
            ]
            // Add more tools as needed
        ]
        
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": [
                "tools": tools
            ]
        ]
        
        await sendResponse(response, outputHandle: outputHandle)
    }
    
    private func handleToolCall(id: Any?, params: [String: Any], outputHandle: FileHandle) async {
        guard let toolName = params["name"] as? String else {
            await sendError(id: id, code: -32602, message: "Missing tool name", outputHandle: outputHandle)
            return
        }
        
        logger.info("Calling tool: \(toolName)")
        
        switch toolName {
        case "bb7_add-todo":
            await handleAddTodo(id: id, params: params, outputHandle: outputHandle)
        default:
            await sendError(id: id, code: -32001, message: "Unknown tool: \(toolName)", outputHandle: outputHandle)
        }
    }
    
    private func handleAddTodo(id: Any?, params: [String: Any], outputHandle: FileHandle) async {
        guard let arguments = params["arguments"] as? [String: Any],
              let title = arguments["title"] as? String else {
            await sendError(id: id, code: -32602, message: "Missing required parameter: title", outputHandle: outputHandle)
            return
        }
        
        // Use Things 3 URL scheme to add todo
        let notes = arguments["notes"] as? String ?? ""
        let tags = arguments["tags"] as? [String] ?? []
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "things"
        urlComponents.host = "add"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "title", value: title)
        ]
        
        if !notes.isEmpty {
            queryItems.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            await sendError(id: id, code: -32603, message: "Failed to create Things URL", outputHandle: outputHandle)
            return
        }
        
        #if canImport(AppKit)
        // Open the URL using NSWorkspace
        let success = NSWorkspace.shared.open(url)
        
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": [
                "content": [
                    [
                        "type": "text",
                        "text": success ? "✅ Task '\(title)' created successfully in Things 3" : "❌ Failed to create task in Things 3"
                    ]
                ],
                "isError": !success
            ]
        ]
        #else
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": [
                "content": [
                    [
                        "type": "text", 
                        "text": "⚠️ Things 3 integration not available on this platform"
                    ]
                ],
                "isError": true
            ]
        ]
        #endif
        
        await sendResponse(response, outputHandle: outputHandle)
    }
    
    private func sendResponse(_ response: [String: Any], outputHandle: FileHandle) async {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await sendStdioData(jsonString, to: outputHandle)
            }
        } catch {
            logger.error("Failed to serialize response: \(error.localizedDescription)")
        }
    }
    
    private func sendError(id: Any?, code: Int, message: String, outputHandle: FileHandle) async {
        let error: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message
            ]
        ]
        
        await sendResponse(error, outputHandle: outputHandle)
    }
    
    private func sendStdioData(_ data: String, to handle: FileHandle) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let dataWithNewline = data + "\n"
                if let data = dataWithNewline.data(using: .utf8) {
                    handle.write(data)
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - Main Entry Point

@main
struct ThingsMCPCLI {
    static func main() async {
        let server = await StdioMCPServer()
        
        // Set up signal handling for graceful shutdown
        signal(SIGINT) { _ in
            Task {
                await server.stop()
                exit(0)
            }
        }
        
        signal(SIGTERM) { _ in
            Task {
                await server.stop()
                exit(0)
            }
        }
        
        await server.start()
        
        // Keep the program running
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // This will keep the program running until interrupted
        }
    }
}
