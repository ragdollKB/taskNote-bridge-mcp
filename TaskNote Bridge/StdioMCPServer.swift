import Foundation
import OSLog
import AppKit

/// Stdio-based MCP server for direct integration with MCP clients like Claude Desktop
struct StdioMCPServer {
    private static var inputBuffer = ""
    
    static func run() async {
        let logger = Logger(subsystem: "com.tasknotebridge.app", category: "StdioMCPServer")
        logger.info("Starting TaskNote Bridge MCP Server in stdio mode")
        
        // Handle stdio communication
        let inputHandle = FileHandle.standardInput
        let outputHandle = FileHandle.standardOutput
        
        // Set up signal handling
        signal(SIGINT, SIG_DFL)
        signal(SIGTERM, SIG_DFL)
        
        logger.info("Stdio server ready, waiting for input...")
        
        // Use DispatchSource for better stdin handling
        let stdinSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: DispatchQueue.global())
        
        stdinSource.setEventHandler {
            let data = inputHandle.availableData
            
            if data.isEmpty {
                logger.info("EOF received, shutting down")
                exit(0)
            }
            
            guard let input = String(data: data, encoding: .utf8) else {
                logger.error("Failed to decode input as UTF-8")
                return
            }
            
            inputBuffer += input
            logger.debug("Received input: \(input.prefix(100))...")
            
            Task {
                await processBufferedInput(outputHandle: outputHandle, logger: logger)
            }
        }
        
        stdinSource.resume()
        
        // Keep the main thread alive
        dispatchMain()
        
        logger.info("Stdio server shutdown complete")
    }
    
    static func processBufferedInput(outputHandle: FileHandle, logger: Logger) async {
        while let lineRange = inputBuffer.range(of: "\n") {
            let line = String(inputBuffer[..<lineRange.lowerBound])
            inputBuffer.removeSubrange(..<lineRange.upperBound)
            
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                logger.debug("Processing line: \(trimmed)")
                await processRequest(trimmed, outputHandle: outputHandle, logger: logger)
            }
        }
    }
    
    static func processRequest(_ input: String, outputHandle: FileHandle, logger: Logger) async {
        logger.info("📥 Received request: \(input)")
        
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
            
            logger.info("Processing method: \(method), id: \(String(describing: id))")
            
            switch method {
            case "initialize":
                await handleInitialize(id, outputHandle, logger)
            case "notifications/initialized":
                // This is a notification - no response expected
                logger.info("Received initialized notification")
            case "tools/list":
                await handleToolsList(id, outputHandle, logger)
            case "resources/list":
                await handleResourcesList(id, outputHandle, logger)
            case "prompts/list":
                await handlePromptsList(id, outputHandle, logger)
            case "tools/call":
                await handleToolCall(id, params, outputHandle, logger)
            default:
                if method.hasPrefix("notifications/") {
                    // Notifications don't require responses
                    logger.info("Received notification: \(method)")
                } else {
                    await sendError(id, -32601, "Method not found: \(method)", outputHandle, logger)
                }
            }
        } catch {
            logger.error("JSON parse error: \(error)")
            await sendError(nil, -32700, "Parse error", outputHandle, logger)
        }
    }

    static func handleInitialize(_ id: Any?, _ outputHandle: FileHandle, _ logger: Logger) async {
        logger.info("Handling initialize request with id: \(String(describing: id))")
        
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [
                        "listChanged": true
                    ],
                    "resources": [
                        "subscribe": false,
                        "listChanged": false
                    ],
                    "prompts": [
                        "listChanged": false
                    ]
                ],
                "serverInfo": [
                    "name": "tasknote-bridge",
                    "version": "1.0.0"
                ]
            ]
        ]
        
        // Log the initialization response
        if let responseData = try? JSONSerialization.data(withJSONObject: response, options: []),
           let responseString = String(data: responseData, encoding: .utf8) {
            logger.info("Sending initialize response: \(responseString)")
        }
        
        await sendResponse(response, outputHandle, logger)
    }
    
    static func handleResourcesList(_ id: Any?, _ outputHandle: FileHandle, _ logger: Logger) async {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "resources": []
            ]
        ]
        await sendResponse(response, outputHandle, logger)
    }
    
    static func handlePromptsList(_ id: Any?, _ outputHandle: FileHandle, _ logger: Logger) async {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "prompts": []
            ]
        ]
        await sendResponse(response, outputHandle, logger)
    }
    
    static func handleToolsList(_ id: Any?, _ outputHandle: FileHandle, _ logger: Logger) async {
        logger.info("Handling tools/list request with id: \(String(describing: id))")
        let tools = getAllMCPTools()
        
        logger.info("Returning \(tools.count) tools")
        for (index, tool) in tools.enumerated() {
            if let name = tool["name"] as? String {
                logger.info("Tool \(index + 1): \(name)")
            }
        }
        
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "tools": tools
            ]
        ]
        
        // Log the response being sent
        if let responseData = try? JSONSerialization.data(withJSONObject: response, options: []),
           let responseString = String(data: responseData, encoding: .utf8) {
            logger.info("Sending tools/list response: \(responseString.prefix(200))...")
        }
        
        await sendResponse(response, outputHandle, logger)
    }
    
    static func handleToolCall(_ id: Any?, _ params: [String: Any]?, _ outputHandle: FileHandle, _ logger: Logger) async {
        guard let params = params,
              let name = params["name"] as? String,
              let arguments = params["arguments"] as? [String: Any] else {
            await sendError(id, -32602, "Invalid params", outputHandle, logger)
            return
        }
        
        logger.info("Executing tool: \(name)")
        
        // Use the integrated Things and Notes tools
        let result = await executeIntegratedTool(name: name, arguments: arguments, logger: logger)
        
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": result
        ]
        await sendResponse(response, outputHandle, logger)
    }
    
    static func sendResponse(_ response: [String: Any], _ outputHandle: FileHandle, _ logger: Logger) async {
        do {
            let data = try JSONSerialization.data(withJSONObject: response)
            if let string = String(data: data, encoding: .utf8) {
                let output = string + "\n"
                if let outputData = output.data(using: .utf8) {
                    outputHandle.write(outputData)
                    logger.info("📤 Sent response: \(string)")
                } else {
                    logger.error("Failed to encode response as UTF-8")
                }
            } else {
                logger.error("Failed to convert response data to string")
            }
        } catch {
            logger.error("Failed to serialize response: \(error)")
        }
    }
    
    static func sendError(_ id: Any?, _ code: Int, _ message: String, _ outputHandle: FileHandle, _ logger: Logger) async {
        let error: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id as Any,
            "error": [
                "code": code,
                "message": message
            ]
        ]
        await sendResponse(error, outputHandle, logger)
    }
}

// MARK: - Tool Definitions and Execution

extension StdioMCPServer {
    
    static func getAllMCPTools() -> [[String: Any]] {
        return [
            // Things 3 Tools
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
                        ],
                        "list_title": [
                            "type": "string",
                            "description": "Project or area name to add the task to"
                        ],
                        "checklist_items": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Checklist items for the task"
                        ]
                    ],
                    "required": ["title"]
                ]
            ],
            [
                "name": "bb7_add-project",
                "description": "Create a new project in Things 3",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "The title of the project"
                        ],
                        "notes": [
                            "type": "string",
                            "description": "Additional notes for the project"
                        ],
                        "area_title": [
                            "type": "string",
                            "description": "Area name to add the project to"
                        ],
                        "tags": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Tags to apply to the project"
                        ],
                        "deadline": [
                            "type": "string",
                            "description": "Due date in YYYY-MM-DD format"
                        ],
                        "when": [
                            "type": "string",
                            "description": "When to start the project"
                        ],
                        "todos": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Initial tasks to create in the project"
                        ]
                    ],
                    "required": ["title"]
                ]
            ],
            [
                "name": "bb7_search-todos",
                "description": "Search for existing tasks in Things 3",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "query": [
                            "type": "string",
                            "description": "Search term to look for in task titles and notes"
                        ]
                    ],
                    "required": ["query"]
                ]
            ],
            [
                "name": "bb7_get-today",
                "description": "Get tasks scheduled for today",
                "inputSchema": [
                    "type": "object",
                    "properties": [:]
                ]
            ],
            [
                "name": "bb7_get-upcoming",
                "description": "Get upcoming tasks",
                "inputSchema": [
                    "type": "object",
                    "properties": [:]
                ]
            ],
            [
                "name": "bb7_get-projects",
                "description": "List all projects in Things 3",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "include_items": [
                            "type": "boolean",
                            "description": "Include tasks within projects",
                            "default": false
                        ]
                    ]
                ]
            ],
            [
                "name": "bb7_open-todo",
                "description": "Search for a task by title and open it in Things 3 app",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "Title or partial title of the task to search for and open"
                        ]
                    ],
                    "required": ["title"]
                ]
            ],
            // Apple Notes Tools  
            [
                "name": "bb7_notes-create",
                "description": "Create a new note in Apple Notes",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "The title of the note"
                        ],
                        "content": [
                            "type": "string",
                            "description": "The content of the note"
                        ],
                        "tags": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Optional tags for the note"
                        ]
                    ],
                    "required": ["title", "content"]
                ]
            ],
            [
                "name": "bb7_notes-search",
                "description": "Search for notes by title in Apple Notes",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "query": [
                            "type": "string",
                            "description": "The search query"
                        ]
                    ],
                    "required": ["query"]
                ]
            ],
            [
                "name": "bb7_notes-list",
                "description": "List all notes in Apple Notes",
                "inputSchema": [
                    "type": "object",
                    "properties": [:]
                ]
            ]
        ]
    }
    
    static func executeIntegratedTool(name: String, arguments: [String: Any], logger: Logger) async -> [String: Any] {
        logger.info("Executing tool: \(name) with arguments: \(arguments)")
        
        switch name {
        case "bb7_add-todo":
            return await executeThingsAddTodo(arguments: arguments, logger: logger)
        case "bb7_add-project":
            return await executeThingsAddProject(arguments: arguments, logger: logger)
        case "bb7_search-todos":
            return await executeThingsSearchTodos(arguments: arguments, logger: logger)
        case "bb7_get-today":
            return await executeThingsGetToday(logger: logger)
        case "bb7_get-upcoming":
            return await executeThingsGetUpcoming(logger: logger)
        case "bb7_get-projects":
            return await executeThingsGetProjects(arguments: arguments, logger: logger)
        case "bb7_open-todo":
            return await executeThingsOpenTodo(arguments: arguments, logger: logger)
        case "bb7_notes-create":
            return await executeNotesCreate(arguments: arguments, logger: logger)
        case "bb7_notes-search":
            return await executeNotesSearch(arguments: arguments, logger: logger)
        case "bb7_notes-list":
            return await executeNotesList(logger: logger)
        default:
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Unknown tool: \(name)"
                    ]
                ],
                "isError": true
            ]
        }
    }
}

// MARK: - Things 3 Tool Implementations

extension StdioMCPServer {
    
    static func executeThingsAddTodo(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        guard let title = arguments["title"] as? String else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Missing required parameter: title"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Create Things URL
        var components = URLComponents(string: "things:///add")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title)
        ]
        
        if let notes = arguments["notes"] as? String, !notes.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if let tags = arguments["tags"] as? [String], !tags.isEmpty {
            let tagsString = tags.joined(separator: ",")
            components.queryItems?.append(URLQueryItem(name: "tags", value: tagsString))
        }
        
        if let deadline = arguments["deadline"] as? String, !deadline.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "deadline", value: deadline))
        }
        
        if let when = arguments["when"] as? String, !when.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "when", value: when))
        }
        
        if let listTitle = arguments["list_title"] as? String, !listTitle.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "list", value: listTitle))
        }
        
        if let checklistItems = arguments["checklist_items"] as? [String], !checklistItems.isEmpty {
            let checklistString = checklistItems.joined(separator: "\n")
            components.queryItems?.append(URLQueryItem(name: "checklist-items", value: checklistString))
        }
        
        guard let url = components.url else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Failed to create Things URL"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Execute the URL scheme
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "✅ Task '\(title)' created in Things 3" : "❌ Failed to create task"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeThingsAddProject(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        guard let title = arguments["title"] as? String else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Missing required parameter: title"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Create Things URL for project
        var components = URLComponents(string: "things:///add-project")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title)
        ]
        
        if let notes = arguments["notes"] as? String, !notes.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if let areaTitle = arguments["area_title"] as? String, !areaTitle.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "area", value: areaTitle))
        }
        
        if let tags = arguments["tags"] as? [String], !tags.isEmpty {
            let tagsString = tags.joined(separator: ",")
            components.queryItems?.append(URLQueryItem(name: "tags", value: tagsString))
        }
        
        if let deadline = arguments["deadline"] as? String, !deadline.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "deadline", value: deadline))
        }
        
        if let when = arguments["when"] as? String, !when.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "when", value: when))
        }
        
        if let todos = arguments["todos"] as? [String], !todos.isEmpty {
            let todosString = todos.joined(separator: "\n")
            components.queryItems?.append(URLQueryItem(name: "to-dos", value: todosString))
        }
        
        guard let url = components.url else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Failed to create Things project URL"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Execute the URL scheme
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "✅ Project '\(title)' created in Things 3" : "❌ Failed to create project"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeThingsSearchTodos(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        guard let query = arguments["query"] as? String else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Missing required parameter: query"
                    ]
                ],
                "isError": true
            ]
        }
        
        // For now, just open Things search with the query
        var components = URLComponents(string: "things:///search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = components.url else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Failed to create Things search URL"
                    ]
                ],
                "isError": true
            ]
        }
        
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "🔍 Opened Things 3 search for: '\(query)'" : "❌ Failed to open search"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeThingsGetToday(logger: Logger) async -> [String: Any] {
        // Open Things today view
        let url = URL(string: "things:///today")!
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "📅 Opened Things 3 Today view" : "❌ Failed to open Today view"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeThingsGetUpcoming(logger: Logger) async -> [String: Any] {
        // Open Things upcoming view
        let url = URL(string: "things:///upcoming")!
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "📆 Opened Things 3 Upcoming view" : "❌ Failed to open Upcoming view"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeThingsGetProjects(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        // Open Things projects view
        let url = URL(string: "things:///projects")!
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "📋 Opened Things 3 Projects view" : "❌ Failed to open Projects view"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeThingsOpenTodo(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        guard let title = arguments["title"] as? String else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Missing required parameter: title"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Search for the todo and open it
        var components = URLComponents(string: "things:///search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: title)
        ]
        
        guard let url = components.url else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Failed to create search URL"
                    ]
                ],
                "isError": true
            ]
        }
        
        let success = await executeURLScheme(url: url, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "🔍 Searched for task: '\(title)' in Things 3" : "❌ Failed to search for task"
                ]
            ],
            "isError": !success
        ]
    }
}

// MARK: - Apple Notes Tool Implementations

extension StdioMCPServer {
    
    static func executeNotesCreate(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        guard let title = arguments["title"] as? String,
              let content = arguments["content"] as? String else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Missing required parameters: title and content"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Use AppleScript to create note
        let script = """
        tell application "Notes"
            make new note at folder "Notes" with properties {name:"\(title.replacingOccurrences(of: "\"", with: "\\\""))", body:"\(content.replacingOccurrences(of: "\"", with: "\\\""))"}
        end tell
        """
        
        let success = await executeAppleScript(script: script, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "📝 Note '\(title)' created in Apple Notes" : "❌ Failed to create note"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeNotesSearch(arguments: [String: Any], logger: Logger) async -> [String: Any] {
        guard let query = arguments["query"] as? String else {
            return [
                "content": [
                    [
                        "type": "text",
                        "text": "❌ Missing required parameter: query"
                    ]
                ],
                "isError": true
            ]
        }
        
        // Use AppleScript to search notes
        let script = """
        tell application "Notes"
            activate
            tell application "System Events"
                keystroke "f" using command down
                delay 0.5
                keystroke "\(query.replacingOccurrences(of: "\"", with: "\\\""))"
            end tell
        end tell
        """
        
        let success = await executeAppleScript(script: script, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "🔍 Searched for '\(query)' in Apple Notes" : "❌ Failed to search notes"
                ]
            ],
            "isError": !success
        ]
    }
    
    static func executeNotesList(logger: Logger) async -> [String: Any] {
        // Open Notes app
        let script = """
        tell application "Notes"
            activate
        end tell
        """
        
        let success = await executeAppleScript(script: script, logger: logger)
        
        return [
            "content": [
                [
                    "type": "text",
                    "text": success ? "📝 Opened Apple Notes" : "❌ Failed to open Notes"
                ]
            ],
            "isError": !success
        ]
    }
}

// MARK: - Utility Functions

extension StdioMCPServer {
    
    static func executeURLScheme(url: URL, logger: Logger) async -> Bool {
        logger.info("Executing URL scheme: \(url.absoluteString)")
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let success = NSWorkspace.shared.open(url)
                logger.info("URL scheme execution result: \(success)")
                continuation.resume(returning: success)
            }
        }
    }
    
    static func executeAppleScript(script: String, logger: Logger) async -> Bool {
        logger.info("Executing AppleScript")
        
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        
        let result = appleScript?.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            logger.error("AppleScript error: \(error)")
            return false
        }
        
        logger.info("AppleScript executed successfully")
        return result != nil
    }
}
