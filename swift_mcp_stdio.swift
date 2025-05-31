#!/usr/bin/swift

//
//  Simple stdio wrapper for SwiftMCPServer
//  This runs the Swift MCP server in stdio mode for VS Code integration
//

import Foundation
import OSLog

// Simple stdio runner without @main conflicts
struct StdioRunner {
    static func run() async {
        let logger = Logger(subsystem: "things-mcp-cli", category: "StdioRunner")
        logger.info("Starting Things MCP Server in stdio mode")
        
        // Handle stdio communication
        let inputHandle = FileHandle.standardInput
        let outputHandle = FileHandle.standardOutput
        
        // Set up signal handling
        signal(SIGINT, SIG_DFL)
        signal(SIGTERM, SIG_DFL)
        
        logger.info("Stdio server ready, waiting for input...")
        
        while true {
            // Read from stdin
            let data = inputHandle.availableData
            
            if data.isEmpty {
                // EOF - client disconnected
                logger.info("EOF received, shutting down")
                break
            }
            
            // Convert to string
            guard let input = String(data: data, encoding: .utf8) else {
                logger.error("Failed to decode input as UTF-8")
                continue
            }
            
            // Skip empty lines
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue
            }
            
            logger.debug("Received: \(trimmed)")
            
            // Process the MCP request
            await processRequest(trimmed, outputHandle: outputHandle, logger: logger)
        }
        
        logger.info("Stdio server shutdown complete")
    }
    
    static func processRequest(_ input: String, outputHandle: FileHandle, logger: Logger) async {
        // Parse JSON-RPC request
        guard let data = input.data(using: .utf8) else {
            await sendError(nil, -32700, "Parse error", outputHandle, logger)
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let method = json?["method"] as? String ?? ""
            let id = json?["id"]
            let params = json?["params"] as? [String: Any]
            
            logger.info("Processing method: \(method)")
            
            switch method {
            case "initialize":
                await handleInitialize(id, outputHandle, logger)
            case "tools/list":
                await handleToolsList(id, outputHandle, logger)
            case "tools/call":
                await handleToolCall(id, params, outputHandle, logger)
            default:
                await sendError(id, -32601, "Method not found: \(method)", outputHandle, logger)
            }
        } catch {
            logger.error("JSON parse error: \(error)")
            await sendError(nil, -32700, "Parse error", outputHandle, logger)
        }
    }
    
    static func handleInitialize(_ id: Any?, _ outputHandle: FileHandle, _ logger: Logger) async {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [:]
                ],
                "serverInfo": [
                    "name": "things-mcp-swift",
                    "version": "1.0.0"
                ]
            ]
        ]
        await sendResponse(response, outputHandle, logger)
    }
    
    static func handleToolsList(_ id: Any?, _ outputHandle: FileHandle, _ logger: Logger) async {
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
                            "description": "Tags to apply to the task"
                        ],
                        "deadline": [
                            "type": "string",
                            "description": "Due date in YYYY-MM-DD format"
                        ],
                        "when": [
                            "type": "string",
                            "description": "Schedule the task (today, tomorrow, evening, anytime, someday)"
                        ]
                    ],
                    "required": ["title"]
                ]
            ]
        ]
        
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": [
                "tools": tools
            ]
        ]
        await sendResponse(response, outputHandle, logger)
    }
    
    static func handleToolCall(_ id: Any?, _ params: [String: Any]?, _ outputHandle: FileHandle, _ logger: Logger) async {
        guard let params = params,
              let name = params["name"] as? String,
              let arguments = params["arguments"] as? [String: Any] else {
            await sendError(id, -32602, "Invalid params", outputHandle, logger)
            return
        }
        
        switch name {
        case "bb7_add-todo":
            await handleAddTodo(id, arguments, outputHandle, logger)
        default:
            await sendError(id, -32001, "Unknown tool: \(name)", outputHandle, logger)
        }
    }
    
    static func handleAddTodo(_ id: Any?, _ args: [String: Any], _ outputHandle: FileHandle, _ logger: Logger) async {
        guard let title = args["title"] as? String else {
            await sendError(id, -32602, "Missing title parameter", outputHandle, logger)
            return
        }
        
        // Create Things URL
        var components = URLComponents(string: "things:///add")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title)
        ]
        
        if let notes = args["notes"] as? String, !notes.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if let tags = args["tags"] as? [String], !tags.isEmpty {
            let tagsString = tags.joined(separator: ",")
            components.queryItems?.append(URLQueryItem(name: "tags", value: tagsString))
        }
        
        if let deadline = args["deadline"] as? String, !deadline.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "deadline", value: deadline))
        }
        
        if let when = args["when"] as? String, !when.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "when", value: when))
        }
        
        guard let url = components.url else {
            await sendError(id, -32603, "Failed to create Things URL", outputHandle, logger)
            return
        }
        
        // Open the URL
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [url.absoluteString]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let success = task.terminationStatus == 0
            let response: [String: Any] = [
                "jsonrpc": "2.0",
                "id": id ?? NSNull(),
                "result": [
                    "content": [
                        [
                            "type": "text",
                            "text": success ? "✅ Task '\(title)' created in Things 3" : "❌ Failed to create task"
                        ]
                    ],
                    "isError": !success
                ]
            ]
            await sendResponse(response, outputHandle, logger)
        } catch {
            await sendError(id, -32603, "Failed to execute: \(error)", outputHandle, logger)
        }
    }
    
    static func sendResponse(_ response: [String: Any], _ outputHandle: FileHandle, _ logger: Logger) async {
        do {
            let data = try JSONSerialization.data(withJSONObject: response)
            if let string = String(data: data, encoding: .utf8) {
                let output = string + "\n"
                if let outputData = output.data(using: .utf8) {
                    outputHandle.write(outputData)
                    logger.debug("Sent response: \(string)")
                }
            }
        } catch {
            logger.error("Failed to serialize response: \(error)")
        }
    }
    
    static func sendError(_ id: Any?, _ code: Int, _ message: String, _ outputHandle: FileHandle, _ logger: Logger) async {
        let error: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message
            ]
        ]
        await sendResponse(error, outputHandle, logger)
    }
}

// Run the stdio server
Task {
    await StdioRunner.run()
    exit(0)
}

// Keep running
RunLoop.main.run()
