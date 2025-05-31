import Foundation
import OSLog
import Network

/// Pure Swift MCP Server Implementation
@MainActor
class SwiftMCPServer: ObservableObject {
    
    // MARK: - Properties
    
    let logger = Logger(subsystem: "com.tasknotebridge.mcp", category: "MCPServer")
    @Published var isRunning = false
    private var tools: [String: ServerMCPTool] = [:]
    
    // TCP Server properties
    private var tcpListener: NWListener?
    private var tcpConnections = Set<TCPConnection>()
    private var tcpPort: UInt16 = 8000

    // Callback properties for logging and monitoring - using Any to avoid type resolution issues for now
    var onLog: ((Any, String, String) -> Void)?
    var onRequest: ((Any) -> Void)?
    var onResponse: ((Any) -> Void)?

    // Server info
    private let serverName = "things-mcp-swift"
    private let serverVersion = "1.0.0"
    private let protocolVersion = "2024-11-05"
    
    init() {
        setupDefaultTools()
    }
    
    // MARK: - Configuration
    
    /// Set the TCP port for the server
    func setTCPPort(_ port: UInt16) {
        guard port > 0 else {
            logger.warning("Attempted to set invalid TCP port: \(port)")
            return
        }
        if tcpListener != nil {
            logger.warning("Cannot change TCP port while server is running. Stop the server first.")
            onLog?("warning", "Cannot change TCP port while server is running.", "SwiftMCPServer.setTCPPort")
            return
        }
        self.tcpPort = port
        logger.info("TCP port set to \(port). Restart server to apply.")
        onLog?("info", "TCP port set to \(port). Restart server to apply.", "SwiftMCPServer.setTCPPort")
    }
    
    // MARK: - Server Lifecycle
    
    /// Start the MCP server with TCP transport
    func start() async {
        guard !isRunning else {
            logger.warning("MCP Server already running")
            return
        }
        
        isRunning = true
        logger.info("Starting Swift MCP Server...")
        DispatchQueue.main.async {
            self.onLog?("info", "Starting Swift MCP Server", "SwiftMCPServer")
        }
        
        // Start TCP server
        await startTCPServer()
    }
    
    /// Stop the MCP server
    func stop() async {
        guard isRunning else { return }
        
        isRunning = false
        await stopTCPServer()

        logger.info("Swift MCP Server stopped")
        DispatchQueue.main.async {
            self.onLog?("info", "Swift MCP Server stopped", "SwiftMCPServer")
        }
    }
    
    // MARK: - Logging
    
    /// Internal log function used throughout the server
    private func log(_ message: String, level: LogLevel, connectionId: UUID? = nil) {
        // Use existing logger property with appropriate log level
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        }
        
        // Also trigger the onLog callback for UI updates
        let source = connectionId != nil ? "SwiftMCPServer - Connection \(connectionId!)" : "SwiftMCPServer"
        DispatchQueue.main.async {
            self.onLog?(level, message, source)
        }
    }

    // MARK: - Request Processing

    /// Processes an MCP request from raw Data and returns raw Data for the response.
    /// This is the core logic unit for all transport listeners.
    public func processMCPDataRequest(requestData: Data, connectionId: UUID?) async -> Data {
        let logPrefix = connectionId.map { "[Connection \($0.uuidString.prefix(8))]" } ?? "[No Connection]"
        var requestId: AnyCodable? // Declare requestId here to ensure it's in scope for catch blocks

        do {
            // Try to extract request ID early for use in all error responses
            requestId = extractRequestId(from: requestData) // Ensure this function is correctly defined and accessible

            let request = try JSONDecoder().decode(MCPRequest.self, from: requestData)
            // Ensure requestId from decoded request is used if available, otherwise keep the one from extractRequestId
            requestId = request.id ?? requestId


            // Process different MCP methods
            switch request.method {
            case "initialize":
                return try await handleInitialize(request) // No label
            case "tools/list":
                return try await handleToolsList(request) // No label
            case "tools/call":
                return try await handleToolCall(request) // No label
            case "resources/list":
                return try await handleResourcesList(request) // No label
            case "resources/read":
                return try await handleResourceRead(request) // No label
            case "prompts/list":
                return try await handlePromptsList(request) // No label
            case "prompts/get":
                return try await handlePromptGet(request) // No label
            default:
                // Use standard JSON-RPC error code for method not found
                throw MCPError(code: -32601, message: "Method not found: \(request.method)")
            }
        } catch let error as DecodingError {
            // requestId should already be set from the attempt in the do block or initial extraction
            let errorMessage: String
            let errorDetails: String
            
            switch error {
            case .dataCorrupted(let context):
                errorMessage = "Data corrupted during decoding"
                errorDetails = "Context: \(context.debugDescription). Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .keyNotFound(let key, let context):
                errorMessage = "Key not found during decoding"
                errorDetails = "Key: \(key.stringValue). Context: \(context.debugDescription). Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMessage = "Type mismatch during decoding"
                errorDetails = "Expected type: \(type). Context: \(context.debugDescription). Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMessage = "Value not found during decoding"
                errorDetails = "Type: \(type). Context: \(context.debugDescription). Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            @unknown default:
                errorMessage = "Unknown decoding error"
                errorDetails = "Error: \(error.localizedDescription)"
            }
            
            logger.error("\(logPrefix) Decoding Error (\(errorMessage)): \(errorDetails). UnderlyingError: \(error.localizedDescription)")
            
            // Extract a snippet of the raw input for debugging
            let rawInputSnippet = String(data: requestData.prefix(200), encoding: .utf8) ?? "Unable to decode snippet"
            
            return createErrorResponseData(id: requestId, code: -32700, message: errorMessage, rawInputSnippet: rawInputSnippet, errorDetails: errorDetails)
        } catch let mcpError as MCPError { // Changed variable name to mcpError to avoid conflict
            // requestId should already be set
            logger.error("\(logPrefix) MCP Error: \(mcpError.errorDescription ?? mcpError.localizedDescription)")
            
            // Pass mcpError.code and mcpError.message directly.
            // For errorDetails, we can pass a string representation of mcpError.data
            let detailsString = mcpError.data.map { String(describing: $0) }
            return createErrorResponseData(id: requestId, code: mcpError.code, message: mcpError.message, errorDetails: detailsString)
        } catch {
            // requestId should already be set
            logger.error("\(logPrefix) Unexpected error: \(error.localizedDescription)")
            return createErrorResponseData(id: requestId, code: -32603, message: "Internal error: \(error.localizedDescription)")
        }
    }

    // Ensure extractRequestId is defined, e.g.:
    private func extractRequestId(from data: Data) -> AnyCodable? {
        // Simplified extraction, assumes MCPRequestMinimal structure
        // A more robust solution might involve trying to decode into a generic dictionary
        // or a struct that only contains `id`, `jsonrpc`, `method`.
        if let minimalRequest = try? JSONDecoder().decode(MCPRequestMinimal.self, from: data) {
            return minimalRequest.id
        }
        return nil // Return nil if ID cannot be extracted
    }

    private func createErrorResponseData(id: AnyCodable?, code: Int, message: String, rawInputSnippet: String? = nil, errorDetails: String? = nil) -> Data {
        var dataPayloadDict: [String: String] = [:]
        if let snippet = rawInputSnippet {
            dataPayloadDict["rawInputSnippet"] = snippet
        }
        if let details = errorDetails {
            dataPayloadDict["details"] = details
        }

        let mcpError = MCPError(code: code, message: message, data: dataPayloadDict.isEmpty ? nil : AnyCodable(dataPayloadDict))
        let result: AnyCodable? = nil
        let response = MCPResponse(id: id ?? AnyCodable(NSNull()), result: result, error: mcpError) // Ensure id is not nil for JSON-RPC spec if original id was nil
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(response)
        } catch {
            // Fallback if encoding the error response itself fails
            let fallbackMessage = "{\"jsonrpc\": \"2.0\", \"id\": null, \"error\": {\"code\": -32603, \"message\": \"Internal error: Failed to encode error response.\"}}"
            return fallbackMessage.data(using: .utf8) ?? Data()
        }
    }
    
    /// Handle incoming MCP request string (primarily for TCP or textual inputs).
    /// Wraps the core data-based processing logic.
    internal func handleRequest(_ input: String) async -> String {
        logger.info("Received raw input string snippet for TCP: \(String(input.prefix(200)))")
        
        let requestIdForError = extractRequestIdFromString(from: input) // Use renamed/new function

        guard let requestData = input.data(using: .utf8) else {
            logger.error("Failed to convert input string to UTF-8 data for TCP handler.")
            let errorData = createErrorResponseData(
                id: requestIdForError,
                code: -32700, // Parse error
                message: "Parse error: Invalid UTF-8 encoding",
                rawInputSnippet: String(input.prefix(200))
            )
            return String(data: errorData, encoding: .utf8) ?? """
            { "jsonrpc": "2.0", "error": { "code": -32603, "message": "Fallback string encoding error" }, "id": null }
            """
        }
        
        let responseData = await processMCPDataRequest(requestData: requestData, connectionId: nil)
        
        if let responseString = String(data: responseData, encoding: .utf8) {
            return responseString
        } else {
            logger.error("Failed to convert response Data to UTF-8 string for TCP handler.")
            // If processMCPDataRequest itself failed and returned an error response, that would be in responseData.
            // This fallback is if the *conversion* of a potentially valid responseData to String fails.
            // We don't have a reliable ID here if responseData isn't a valid MCP JSON string.
            // Try to extract ID from the original input string for this ultimate fallback.
            let fallbackId = extractRequestIdFromString(from: input)
            let errorData = createErrorResponseData(
                id: fallbackId,
                code: -32603, // Internal error
                message: "Internal error: Failed to convert response data to string"
            )
            return String(data: errorData, encoding: .utf8) ?? """
            { "jsonrpc": "2.0", "error": { "code": -32603, "message": "Fallback string encoding error" }, "id": null }
            """
        }
    }

    // Renamed from extractRequestIdAnyCodable to extractRequestIdFromString
    private func extractRequestIdFromString(from input: String) -> AnyCodable? {
        // Basic extraction, assumes ID is an Int or String and near the beginning.
        // This is a fallback and might not cover all JSON structures perfectly.
        if let data = input.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let idValue = json["id"] {
                        return AnyCodable(idValue) // Let AnyCodable handle Int, String, etc.
                    }
                }
            } catch {
                logger.warning("Could not extract request ID from raw input during fallback: \(error.localizedDescription)")
            }
        }
        return nil
    }

    // REMOVE THE DUPLICATE createErrorResponseData (previously lines 340-381)
    // private func createErrorResponseData(id: AnyCodable?, code: Int, message: String, rawInputSnippet: String? = nil, errorDetails: String? = nil) -> Data { ... }

    // REMOVE REDUNDANT processRequest
    // private func processRequest(_ request: MCPRequest) async -> MCPResponse { ... }
    
    // MARK: - MCP Method Handlers
    
    /// Handle initialization request
    private func handleInitialize(_ request: MCPRequest) async throws -> Data {
        logger.info("[TCP Test - handleInitialize] Entered for request ID: \(String(describing: request.id))")
        let result: [String: Any] = [
            "protocolVersion": protocolVersion,
            "capabilities": [
                "tools": [
                    "listChanged": false // Per MCP spec, this indicates if tool list can change dynamically
                ],
                "resources": [ // Example: Add resource capabilities if supported
                    "subscribe": false,
                    "listChanged": false
                ],
                "prompts": [ // Example: Add prompt capabilities if supported
                    "listChanged": false
                ]
            ],
            "serverInfo": [
                "name": serverName,
                "version": serverVersion
            ]
        ]
        
        logger.info("[TCP Test - handleInitialize] Prepared result: \(String(describing: result))")
        // TODO: Fix type resolution - for now return simple JSON
        let simpleResponse = ["jsonrpc": "2.0", "id": 1, "result": result] as [String: Any]
        return try JSONSerialization.data(withJSONObject: simpleResponse)
    }
    
    /// Handle tools list request
    private func handleToolsList(_ request: MCPRequest) async throws -> Data {
        let toolDefinitions = tools.values.map { $0.definition }
        
        do {
            // MCPToolDefinition is Codable. We need to convert it to [String: Any] for the MCPResponse.
            // Or, ensure MCPResponse can take [MCPToolDefinition] directly if its `result` field is flexible enough.
            // Current MCPResponse.result is [String: AnyCodable]?.
            // So, the "tools" key should map to an array of dictionaries.

            let toolDictsArray = try toolDefinitions.map { toolDef -> [String: AnyCodable] in
                let toolData = try JSONEncoder().encode(toolDef)
                guard let toolDict = try JSONSerialization.jsonObject(with: toolData) as? [String: Any] else {
                    throw MCPServerError.executionError("Failed to serialize tool definition to dictionary")
                }
                return toolDict.mapValues { AnyCodable($0) }
            }
            
            let result: [String: AnyCodable] = [ // Ensure this matches MCPResponse's expectation
                "tools": AnyCodable(toolDictsArray)
            ]
            
            let response = MCPResponse(id: request.id, result: result.mapValues { $0.value }) // Convert back for MCPResponse init
            return try JSONEncoder().encode(response)
        } catch {
            logger.error("Failed to encode tools list response: \(error.localizedDescription)")
            // Create an error MCPResponse and encode that
            let mcpError = MCPError(code: -32603, message: "Failed to encode tools: \(error.localizedDescription)")
            let errorResponse = MCPResponse(id: request.id, error: mcpError)
            return try JSONEncoder().encode(errorResponse) // This could also throw, but processMCPDataRequest will catch it
        }
    }
    
    /// Handle tool call request
    private func handleToolCall(_ request: MCPRequest) async throws -> Data {
        guard let params = request.params,
              let toolNameAnyCodable = params["name"],
              let toolName = toolNameAnyCodable.value as? String else {
            let error = MCPError(code: -32602, message: "Invalid parameters: missing or invalid tool name")
            let response = MCPResponse(id: request.id, error: error)
            return try JSONEncoder().encode(response)
        }
        
        guard let tool = tools[toolName] else {
            let error = MCPError(code: -32001, message: "Tool not found: \(toolName)") // MCP specific error code
            let response = MCPResponse(id: request.id, error: error)
            return try JSONEncoder().encode(response)
        }
        
        // Extract arguments, converting from [String: AnyCodable] to [String: Any]
        var arguments: [String: Any] = [:]
        if let argumentsAnyCodable = params["arguments"],
           let argumentsDict = argumentsAnyCodable.value as? [String: AnyCodable] {
            for (key, anyCodable) in argumentsDict {
                arguments[key] = anyCodable.value
            }
        } else if let argumentsAnyCodable = params["arguments"],
                  let argumentsDictPlain = argumentsAnyCodable.value as? [String: Any] { // Handle if it's already [String: Any]
             arguments = argumentsDictPlain
        }
        
        do {
            let mcpContentArray = try await tool.handler(arguments)
            
            // Convert [MCPContent] to [[String: Any]] for the response
            let contentDictionaries: [[String: Any]] = try mcpContentArray.map { mcpContent in
                let data = try JSONEncoder().encode(mcpContent) // MCPContent is Codable
                guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw MCPServerError.executionError("Failed to serialize MCPContent item to dictionary")
                }
                return dictionary
            }
            
            let result: [String: Any] = [
                "content": contentDictionaries,
                "isError": false
            ]
            
            let response = MCPResponse(id: request.id, result: result)
            return try JSONEncoder().encode(response)
            
        } catch {
            logger.error("Tool execution error for '\(toolName)': \(error.localizedDescription)")
            
            // MCP Spec for tool call error: result should contain content with error, and isError: true
            let errorContent: [[String: Any]] = [
                ["type": "text", "text": "Tool execution failed for '\(toolName)': \(error.localizedDescription)"]
            ]
            let resultWithError: [String: Any] = [
                "content": errorContent,
                "isError": true
            ]
            // Though the spec says result.isError, the primary error reporting is via the main "error" field of JSON-RPC.
            // Let's use the main error field for tool execution failures for consistency with other errors.
            let mcpError = MCPError(code: -32002, message: "Tool execution failed for '\(toolName)': \(error.localizedDescription)")
            let errorResponse = MCPResponse(id: request.id, error: mcpError)
            // If we must use result.isError, then the MCPResponse would not have the top-level 'error' field.
            // Sticking to top-level 'error' for now.
            return try JSONEncoder().encode(errorResponse)
        }
    }

    // Stubs for missing handlers
    private func handleResourcesList(_ request: MCPRequest) async throws -> Data {
        logger.warning("Method 'resources/list' not implemented.")
        let error = MCPError(code: -32601, message: "Method 'resources/list' not implemented.")
        let response = MCPResponse(id: request.id, error: error)
        return try JSONEncoder().encode(response)
    }

    private func handleResourceRead(_ request: MCPRequest) async throws -> Data {
        logger.warning("Method 'resources/read' not implemented.")
        let error = MCPError(code: -32601, message: "Method 'resources/read' not implemented.")
        let response = MCPResponse(id: request.id, error: error)
        return try JSONEncoder().encode(response)
    }

    private func handlePromptsList(_ request: MCPRequest) async throws -> Data {
        logger.warning("Method 'prompts/list' not implemented.")
        let error = MCPError(code: -32601, message: "Method 'prompts/list' not implemented.")
        let response = MCPResponse(id: request.id, error: error)
        return try JSONEncoder().encode(response)
    }

    private func handlePromptGet(_ request: MCPRequest) async throws -> Data {
        logger.warning("Method 'prompts/get' not implemented.")
        let error = MCPError(code: -32601, message: "Method 'prompts/get' not implemented.")
        let response = MCPResponse(id: request.id, error: error)
        return try JSONEncoder().encode(response)
    }
    
    // MARK: - Tool Registration
    
    /// Register a tool with the server
    func registerTool(
        name: String,
        description: String,
        parameters: [String: MCPProperty] = [:],
        requiredParams: [String] = [],
        handler: @escaping ([String: Any]) async throws -> [MCPContent]
    ) {
        let schema = MCPSchema(
            type: "object",
            properties: parameters.isEmpty ? nil : parameters,
            required: requiredParams.isEmpty ? nil : requiredParams
        )
        
        let definition = MCPToolDefinition(
            name: name,
            description: description,
            inputSchema: schema
        )
        
        let tool = ServerMCPTool(definition: definition, handler: handler) // Changed MCPTool to ServerMCPTool
        tools[name] = tool
        
        logger.info("Registered tool: \(name)")
        DispatchQueue.main.async {
            self.onLog?("info", "Registered tool: \(name)", "SwiftMCPServer")
        }
    }
}

// MARK: - Default Tools Setup

// Helper struct for internal tool storage
fileprivate struct ServerMCPTool {
    let definition: MCPToolDefinition
    let handler: ([String: Any]) async throws -> [MCPContent]
}

extension SwiftMCPServer {
    
    /// Setup default Things 3 and Apple Notes tools
    private func setupDefaultTools() {
        // Register Things 3 tools
        registerThingsTools()
        
        // Register Apple Notes tools
        registerNotesTools()
    }
    
    /// Register Things 3 related tools
    private func registerThingsTools() {
        // bb7_add-todo
        registerTool(
            name: "bb7_add-todo",
            description: "Create a new task in Things 3",
            parameters: [
                "title": MCPProperty(type: "string", description: "Task title"),
                "notes": MCPProperty(type: "string", description: "Task notes"),
                "deadline": MCPProperty(type: "string", description: "Deadline in YYYY-MM-DD format"),
                "tags": MCPProperty(type: "array", description: "Array of tag names", items: MCPProperty(type: "string")),
                "when": MCPProperty(type: "string", description: "When to schedule (today, tomorrow, evening, anytime, someday, or YYYY-MM-DD)"),
                "checklist_items": MCPProperty(type: "array", description: "Checklist items", items: MCPProperty(type: "string")),
                "list_title": MCPProperty(type: "string", description: "Project or area title to add to"),
                "list_id": MCPProperty(type: "string", description: "Project or area ID to add to"),
                "heading": MCPProperty(type: "string", description: "Heading to add under")
            ],
            requiredParams: ["title"]
        ) { params in
            return try await ThingsIntegration.addTodo(params)
        }
        
        // bb7_add-project
        registerTool(
            name: "bb7_add-project",
            description: "Create a new project in Things 3",
            parameters: [
                "title": MCPProperty(type: "string", description: "Project title"),
                "notes": MCPProperty(type: "string", description: "Project notes"),
                "area_title": MCPProperty(type: "string", description: "Area title to add to"),
                "area_id": MCPProperty(type: "string", description: "Area ID to add to"),
                "tags": MCPProperty(type: "array", description: "Array of tag names", items: MCPProperty(type: "string")),
                "deadline": MCPProperty(type: "string", description: "Deadline in YYYY-MM-DD format"),
                "when": MCPProperty(type: "string", description: "When to schedule the project"),
                "todos": MCPProperty(type: "array", description: "Initial todos to create in the project", items: MCPProperty(type: "string"))
            ],
            requiredParams: ["title"]
        ) { params in
            return try await ThingsIntegration.addProject(params)
        }
        
        // bb7_search-todos
        registerTool(
            name: "bb7_search-todos",
            description: "Search for existing tasks",
            parameters: [
                "query": MCPProperty(type: "string", description: "Search term to look for in todo titles and notes")
            ],
            requiredParams: ["query"]
        ) { params in
            return try await ThingsIntegration.searchTodos(params)
        }
        
        // bb7_open-todo
        registerTool(
            name: "bb7_open-todo",
            description: "Search for a todo by title and open it in Things 3 app",
            parameters: [
                "title": MCPProperty(type: "string", description: "Title or partial title of the todo to search for and open")
            ],
            requiredParams: ["title"]
        ) { params in
            return try await ThingsIntegration.openTodo(params)
        }
        
        // bb7_get-today
        registerTool(
            name: "bb7_get-today",
            description: "Get todos due today",
            parameters: [:]
        ) { params in
            return try await ThingsIntegration.getToday(params)
        }
        
        // bb7_get-upcoming
        registerTool(
            name: "bb7_get-upcoming",
            description: "Get upcoming todos",
            parameters: [:]
        ) { params in
            return try await ThingsIntegration.getUpcoming(params)
        }
        
        // bb7_get-anytime
        registerTool(
            name: "bb7_get-anytime",
            description: "Get todos from Anytime list",
            parameters: [:]
        ) { params in
            return try await ThingsIntegration.getAnytime(params)
        }
    }
    
    /// Register Apple Notes related tools
    private func registerNotesTools() {
        // bb7_notes-create
        registerTool(
            name: "bb7_notes-create",
            description: "Create a new note in Apple Notes",
            parameters: [
                "title": MCPProperty(type: "string", description: "Note title"),
                "content": MCPProperty(type: "string", description: "Note content"),
                "tags": MCPProperty(type: "array", description: "Array of tag names", items: MCPProperty(type: "string"))
            ],
            requiredParams: ["title", "content"]
        ) { params in
            return try await NotesIntegration.createNote(params)
        }
        
        // bb7_notes-search
        registerTool(
            name: "bb7_notes-search",
            description: "Search for notes by title in Apple Notes",
            parameters: [
                "query": MCPProperty(type: "string", description: "Search query")
            ],
            requiredParams: ["query"]
        ) { params in
            return try await NotesIntegration.searchNotes(params)
        }
        
        // bb7_notes-get-content
        registerTool(
            name: "bb7_notes-get-content",
            description: "Get the content of a specific note from Apple Notes",
            parameters: [
                "title": MCPProperty(type: "string", description: "Exact title of the note")
            ],
            requiredParams: ["title"]
        ) { params in
            return try await NotesIntegration.getNoteContent(params)
        }
        
        // bb7_notes-list
        registerTool(
            name: "bb7_notes-list",
            description: "List all notes in Apple Notes",
            parameters: [:]
        ) { params in
            return try await NotesIntegration.listNotes(params)
        }
        
        // bb7_notes-open
        registerTool(
            name: "bb7_notes-open",
            description: "Open a note in Apple Notes app",
            parameters: [
                "title": MCPProperty(type: "string", description: "Exact title of the note to open")
            ],
            requiredParams: ["title"]
        ) { params in
            return try await NotesIntegration.openNote(params)
        }
        
        // bb7_notes-delete
        registerTool(
            name: "bb7_notes-delete",
            description: "Delete a note from Apple Notes",
            parameters: [
                "title": MCPProperty(type: "string", description: "Exact title of the note to delete")
            ],
            requiredParams: ["title"]
        ) { params in
            return try await NotesIntegration.deleteNote(params)
        }
    }
}

// MARK: - Error Types

enum MCPServerError: Error {
    case invalidInput(String)
    case toolNotFound(String)
    case executionError(String)
}

extension MCPServerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .toolNotFound(let tool):
            return "Tool not found: \(tool)"
        case .executionError(let message):
            return "Execution error: \(message)"
        }
    }
}

// MARK: - TCP Server Implementation

extension SwiftMCPServer {
    
    /// Start the TCP server
    private func startTCPServer() async {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            tcpListener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: tcpPort))
            
            tcpListener?.newConnectionHandler = { [weak self] newConnection in
                Task {
                    await self?.handleNewTCPConnection(newConnection)
                }
            }
            
            tcpListener?.start(queue: .global(qos: .userInitiated))
            
            logger.info("TCP Server started on port \(self.tcpPort)")
            DispatchQueue.main.async {
                self.onLog?("info", "TCP Server started on port \(self.tcpPort)", "SwiftMCPServer")
            }
            
        } catch {
            logger.error("Failed to start TCP server: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.onLog?(.error, "Failed to start TCP server: \(error.localizedDescription)", "SwiftMCPServer")
            }
        }
    }
    
    /// Stop the TCP server
    private func stopTCPServer() async {
        tcpListener?.cancel()
        tcpListener = nil
        
        // Close all connections
        for connection in tcpConnections {
            await connection.close()
        }
        tcpConnections.removeAll()
        
        logger.info("TCP Server stopped")
        DispatchQueue.main.async {
            self.onLog?("info", "TCP Server stopped", "SwiftMCPServer")
        }
    }
    
    /// Handle new TCP connection
    private func handleNewTCPConnection(_ nwConnection: NWConnection) async {
        logger.info("[TCP Server] Accepting new connection from listener.")
        let connection = TCPConnection(nwConnection: nwConnection, server: self)
        tcpConnections.insert(connection)
        
        // nwConnection.start will trigger the stateUpdateHandler in TCPConnection
        nwConnection.start(queue: .global(qos: .userInitiated))
        
        // No longer call connection.startReceiving() here
        // The log "New TCP connection established" will now effectively be when the state becomes .ready in the handler.
    }
    
    /// Handle TCP message from connection
    func handleTCPMessage(_ message: String, from connection: TCPConnection) async {
        logger.info("[TCP Test - handleTCPMessage] Received message: \(message)")
        let response = await handleRequest(message)
        logger.info("[TCP Test - handleTCPMessage] Sending response: \(response)")
        await connection.send(response)
    }
    
    /// Remove TCP connection
    func removeTCPConnection(_ connection: TCPConnection) {
        tcpConnections.remove(connection)
        logger.info("TCP connection removed")
        DispatchQueue.main.async {
            self.onLog?("info", "TCP connection removed", "SwiftMCPServer")
        }
    }
}

// MARK: - TCP Connection Handler

/// Handles individual TCP client connections
@MainActor // Ensure TCPConnection is managed on the MainActor
class TCPConnection: Identifiable, Hashable {
    private let nwConnection: NWConnection
    private weak var server: SwiftMCPServer?
    let id = UUID() // Made internal to satisfy Identifiable
    private var messageBuffer = ""
    private var messageData: Data = Data()
    private var isConnectionClosed: Bool = false
    
    var didStopCallback: ((Error?, UUID) -> Void)? // Updated to include UUID
    
    init(nwConnection: NWConnection, server: SwiftMCPServer) {
        self.nwConnection = nwConnection
        self.server = server
        self.server?.logger.info("[TCP Connection \(self.id.uuidString.prefix(8))] Initialized.")
        setupStateUpdateHandler()
    }
    
    private func setupStateUpdateHandler() {
        nwConnection.stateUpdateHandler = { [weak self] newState in
            guard let self = self else { return }
            // Accessing self.server (MainActor isolated) from a Sendable closure.
            // Wrap in Task { @MainActor in ... }
            Task { @MainActor in
                self.server?.logger.info("[TCP Connection \\(self.id.uuidString.prefix(8))] State changed: \\(String(describing: newState))")
            }
            
            switch newState {
            case .ready:
                Task { @MainActor in
                    self.server?.logger.info("[TCP Connection \\(self.id.uuidString.prefix(8))] State is READY. Starting receive loop.")
                    self.server?.onLog?(.info, "TCP Connection \\(self.id.uuidString.prefix(8)) established.", "TCPConnection")
                }
                Task { // Launch as a new Task to not block the stateUpdateHandler
                    await self.receiveMessages()
                }
            case .failed(let error):
                Task { @MainActor in
                    self.server?.logger.error("[TCP Connection \\(self.id.uuidString.prefix(8))] State is FAILED. Error: \\(error.localizedDescription)")
                    self.server?.onLog?(.error, "TCP Connection \\(self.id.uuidString.prefix(8)) failed: \\(error.localizedDescription)", "TCPConnection")
                }
                self.nwConnection.cancel() // Ensure connection is cancelled before removing
                Task { @MainActor in
                    self.server?.removeTCPConnection(self)
                }
            case .cancelled:
                Task { @MainActor in
                    self.server?.logger.info("[TCP Connection \\(self.id.uuidString.prefix(8))] State is CANCELLED.")
                    self.server?.onLog?(.info, "TCP Connection \\(self.id.uuidString.prefix(8)) cancelled.", "TCPConnection")
                    self.server?.removeTCPConnection(self) // removeTCPConnection is idempotent
                }
            case .preparing:
                Task { @MainActor in
                    self.server?.logger.info("[TCP Connection \\(self.id.uuidString.prefix(8))] State is PREPARING.")
                }
            case .setup:
                Task { @MainActor in
                    self.server?.logger.info("[TCP Connection \\(self.id.uuidString.prefix(8))] State is SETUP.")
                }
            case .waiting(let error):
                Task { @MainActor in
                    self.server?.logger.warning("[TCP Connection \\(self.id.uuidString.prefix(8))] State is WAITING. Error: \\(error.localizedDescription)")
                    self.server?.onLog?(.warning, "TCP Connection \\(self.id.uuidString.prefix(8)) waiting: \\(error.localizedDescription)", "TCPConnection")
                }
            @unknown default:
                Task { @MainActor in
                    self.server?.logger.warning("[TCP Connection \\(self.id.uuidString.prefix(8))] State is UNKNOWN: \\(String(describing: newState))")
                }
            }
        }
    }
    
    // Removed startReceiving() method as its logic is now initiated by the stateUpdateHandler

    /// Send a message to the client
    func send(_ message: String) async {
        let data = (message + "\n").data(using: .utf8) ?? Data()
        // Accessing self.server (MainActor isolated) from a Sendable closure.
        // Wrap in Task { @MainActor in ... }
        Task { @MainActor in
            self.server?.logger.info("[TCP Test - TCPConnection send] Attempting to send data (\\(data.count) bytes) for connection ID \\(self.id): \\(message.prefix(200))")
        }
        
        await withCheckedContinuation { continuation in
            nwConnection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self = self else { continuation.resume(); return }
                Task { @MainActor in // Wrap server access in MainActor task
                    if let error = error {
                        self.server?.logger.error("[TCP Test - TCPConnection send] TCP send error for connection ID \\(self.id): \\(error.localizedDescription)")
                    } else {
                        self.server?.logger.info("[TCP Test - TCPConnection send] Successfully sent data for connection ID \\(self.id).")
                    }
                }
                continuation.resume()
            })
        }
    }
    
    /// Close the connection
    func close() async {
        nwConnection.cancel()
        // removeTCPConnection is a synchronous MainActor func, await is not needed if called from MainActor context
        // However, close() itself is async, so if it's called from a non-main actor context,
        // we need to ensure removeTCPConnection is called on the main actor.
        // Since TCPConnection is @MainActor, server.remove is fine without await if server is also @MainActor.
        // The warning was "no 'async' operations occur within 'await' expression".
        // Let's remove await as removeTCPConnection is sync.
        server?.removeTCPConnection(self)
    }
    
    /// Continuously receive messages
    private func receiveMessages() async {
        guard !isConnectionClosed else {
            server?.logger.debug("[TCP Connection \(self.id.uuidString.prefix(8))] Not receiving, connection is closed.")
            return
        }
        server?.logger.debug("[TCP Connection \(self.id.uuidString.prefix(8))] Entering receiveMessages loop.")
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536 * 10) { [weak self] (data, context, isComplete, error) in
            guard let self = self else { return }

            Task { // Process received data and potential errors in an async Task
                if let error = error {
                    self.server?.logger.error("[TCPConnection \\(self.id.uuidString.prefix(8))] Receive error: \\(error.localizedDescription)")
                    await self.closeConnection(reason: "Receive error: \\(error.localizedDescription)")
                    return
                }

                if isComplete {
                    self.server?.logger.info("[TCPConnection \\(self.id.uuidString.prefix(8))] Connection did close (isComplete=true).")
                    await self.closeConnection(reason: "Connection closed by remote peer (isComplete)")
                    return
                }

                if let data = data, !data.isEmpty {
                    Task { @MainActor in // Wrap server access
                        self.server?.logger.info("[TCPConnection \\\\(self.id.uuidString.prefix(8))] Received \\\\(data.count) bytes.")
                    }
                    // Process the received data
                    // Pass self.id (UUID) directly
                    let responseData = await self.server?.processMCPDataRequest(requestData: data, connectionId: self.id)
                    if let responseData = responseData, !responseData.isEmpty {
                        // send(data:) is already async and handles its own MainActor tasks for logging
                        await self.send(data: responseData)
                    } else {
                        Task { @MainActor in // Wrap server access
                            self.server?.logger.warning("[TCPConnection \\\\(self.id.uuidString.prefix(8))] No response data to send or processMCPDataRequest returned empty.")
                        }
                    }
                }
                
                // If not complete and no error, continue receiving
                if !isComplete && error == nil {
                    await self.receiveMessages()
                }
            }
        }
    }

    private func processBufferedMessages() {
        guard var messageBufferString = String(data: messageData, encoding: .utf8) else {
            server?.logger.error("Error: Could not decode messageData to UTF-8 string.")
            return
        }
        server?.logger.debug("[TCP Test - processBufferedMessages] Connection \(self.id.uuidString.prefix(8)): Processing buffer. Size: \(self.messageData.count) bytes. Content (first 200): '\(messageBufferString.prefix(200))'. Contains newline: \(messageBufferString.contains("\n"))")

        var processedAnyMessages = false

        while let newlineRange = messageBufferString.firstRange(of: "\n") {
            processedAnyMessages = true
            // Extract the message part (everything before the newline)
            let messagePartString = String(messageBufferString[..<newlineRange.lowerBound])
            server?.logger.debug("[TCP Test - processBufferedMessages] Connection \(self.id.uuidString.prefix(8)): Found newline. Extracted message part (first 200): '\(messagePartString.prefix(200))'")

            // Guard against empty messages (e.g. if buffer was just "\n")
            guard !messagePartString.isEmpty else {
                server?.logger.debug("[TCP Test - processBufferedMessages] Connection \(self.id.uuidString.prefix(8)): Extracted empty message part (likely just a newline). Skipping.")
                // Consume the newline and continue
                if newlineRange.upperBound >= messageBufferString.endIndex {
                    messageBufferString = ""
                } else {
                    messageBufferString = String(messageBufferString[newlineRange.upperBound...])
                }
                continue
            }

            guard let messagePartData = messagePartString.data(using: .utf8) else {
                server?.logger.error("Error: Could not re-encode message part to UTF-8 data. Original string: \(messagePartString.prefix(200))")
                // Consume and continue to prevent infinite loops on bad data.
                if newlineRange.upperBound >= messageBufferString.endIndex {
                    messageBufferString = ""
                } else {
                    messageBufferString = String(messageBufferString[newlineRange.upperBound...])
                }
                continue
            }
            
            server?.logger.info("Processing request: \(messagePartString.prefix(500))")

            Task {
                if let server = self.server {
                    let responseData = await server.processMCPDataRequest(requestData: messagePartData, connectionId: self.id)
                    self.sendResponse(responseData)
                } else {
                    self.server?.logger.error("TCPConnection \(self.id.uuidString.prefix(8)): Server reference is nil, cannot process request.")
                }
            }

            // Update the buffer by removing the processed message and the newline
            if newlineRange.upperBound >= messageBufferString.endIndex {
                messageBufferString = "" // Consumed the whole buffer
            } else {
                messageBufferString = String(messageBufferString[newlineRange.upperBound...])
            }
            server?.logger.debug("[TCP Test - processBufferedMessages] Connection \(self.id.uuidString.prefix(8)): Buffer after removing processed part (first 200): '\(messageBufferString.prefix(200))'")
        } // End of while loop

        if !processedAnyMessages && !messageBufferString.isEmpty {
            server?.logger.debug("[TCP Test - processBufferedMessages] Connection \(self.id.uuidString.prefix(8)): No complete message (newline) found in current buffer. Buffer (first 200): '\(messageBufferString.prefix(200))'")
        }
        
        if let remainingData = messageBufferString.data(using: .utf8) {
            self.messageData = remainingData
        } else {
            server?.logger.error("Error: Could not encode remaining messageBufferString to UTF-8. Buffer may be corrupted. Original string: \(messageBufferString.prefix(200))")
            // self.messageData = Data() // Optionally clear corrupted buffer
        }
        server?.logger.debug("[TCP Test - processBufferedMessages] Connection \(self.id.uuidString.prefix(8)): Finished processing. Remaining buffer size: \(self.messageData.count) bytes. Content (first 200): '\(String(data: self.messageData, encoding: .utf8)?.prefix(200) ?? "DECODING_ERROR")'")
    }

    /// Send response data to the client
    private func sendResponse(_ responseData: Data) {
        Task {
            if let responseString = String(data: responseData, encoding: .utf8) {
                await self.send(responseString)
            } else {
                server?.logger.error("Failed to convert response data to string")
            }
        }
    }
    
    /// Close the connection with a reason
    @MainActor
    private func closeConnection(reason: String) {
        guard !isConnectionClosed else { return }
        
        isConnectionClosed = true
        server?.logger.info("[TCP Connection \(self.id.uuidString.prefix(8))] Closing connection. Reason: \(reason)")
        
        nwConnection.cancel()
        server?.removeTCPConnection(self)
    }

    /// Send data to the client
    func send(data: Data) async {
        await withCheckedContinuation { continuation in
            nwConnection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self = self else { continuation.resume(); return }
                Task { @MainActor in // Wrap server access in MainActor task
                    if let error = error {
                        self.server?.logger.error("[TCP Connection send(data:)] Error: \\(error.localizedDescription)")
                    }
                }
                continuation.resume()
            })
        }
    }
    
    /// Stop the connection with error handling
    @MainActor
    func stop(error: Error? = nil) {
        guard !isConnectionClosed else { return }
        
        isConnectionClosed = true
        server?.logger.info("[TCP Connection \(self.id.uuidString.prefix(8))] Stopping connection. Error: \(error?.localizedDescription ?? "None")")
        
        nwConnection.cancel()
        
        // Notify the server that this connection stopped, passing the ID
        didStopCallback?(error, id) // Pass id here
        didStopCallback = nil // Avoid re-calling
        
        server?.removeTCPConnection(self)
    }

    // MARK: - Hashable
    
    nonisolated func hash(into hasher: inout Hasher) { // Added nonisolated
        hasher.combine(id)
    }
    
    nonisolated static func == (lhs: TCPConnection, rhs: TCPConnection) -> Bool { // Added nonisolated
        return lhs.id == rhs.id
    }
}

// Extension to help convert AnyCodable to String for logging/details
extension AnyCodable {
    func valueAsString() -> String? {
        guard let val = self.value else { return nil }
        if let str = val as? String {
            return str
        } else if let dict = val as? [String: Any] {
            // Attempt to serialize dictionary back to JSON string for details
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return String(describing: dict)
            }
        } else {
            return String(describing: val)
        }
    }
}
