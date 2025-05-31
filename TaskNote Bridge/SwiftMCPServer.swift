import Foundation
import OSLog
import Network

/// Transport mode for MCP server
enum MCPTransportMode {
    case tcp(port: UInt16)
    case stdio
}

/// Pure Swift MCP Server Implementation - Minimal Working Version with TCP and stdio support
@MainActor
class SwiftMCPServer: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isRunning = false
    @Published var status = "Stopped"
    @Published var lastError: String?
    
    private let logger = Logger(subsystem: "things-mcp", category: "SwiftMCPServer")
    
    // TCP transport
    private var tcpListener: NWListener?
    private var connections: [NWConnection] = []
    private var port: UInt16 = 3001
    
    // stdio transport
    private var stdioTask: Task<Void, Never>?
    
    // Transport mode
    private var transportMode: MCPTransportMode = .tcp(port: 3001)
    
    // MARK: - Callback Properties (for MCPService compatibility)
    
    var onLog: ((String, String, String) -> Void)?
    var onRequest: ((Any) -> Void)?
    var onResponse: ((Any) -> Void)?
    
    // MARK: - Lifecycle
    
    init() {
        logger.info("SwiftMCPServer initialized")
    }
    
    // MARK: - Interface Methods (for MCPService compatibility)
    
    func setTCPPort(_ newPort: UInt16) {
        port = newPort
        transportMode = .tcp(port: newPort)
        logger.info("TCP port set to \(newPort)")
    }
    
    func setStdioMode() {
        transportMode = .stdio
        logger.info("Transport mode set to stdio")
    }
    
    // MARK: - Server Control
    
    func start() async {
        guard !isRunning else {
            logger.warning("Server already running")
            return
        }
        
        do {
            switch transportMode {
            case .tcp(let tcpPort):
                port = tcpPort
                try await startTCPServer()
                status = "Running on TCP port \(port)"
            case .stdio:
                await startStdioServer()
                status = "Running on stdio"
            }
            
            isRunning = true
            lastError = nil
            logger.info("SwiftMCPServer started successfully in transport mode")
        } catch {
            lastError = error.localizedDescription
            status = "Failed to start: \(error.localizedDescription)"
            logger.error("Failed to start server: \(error.localizedDescription)")
        }
    }
    
    func stop() async {
        guard isRunning else { return }
        
        switch transportMode {
        case .tcp:
            tcpListener?.cancel()
            tcpListener = nil
            
            // Close all connections
            for connection in connections {
                connection.cancel()
            }
            connections.removeAll()
            
        case .stdio:
            stdioTask?.cancel()
            stdioTask = nil
        }
        
        isRunning = false
        status = "Stopped"
        logger.info("SwiftMCPServer stopped")
    }
    
    // MARK: - TCP Server
    
    private func startTCPServer() async throws {
        let parameters = NWParameters.tcp
        tcpListener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
        
        tcpListener?.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                await self?.handleNewConnection(connection)
            }
        }
        
        tcpListener?.start(queue: .main)
        logger.info("TCP server started on port \(self.port)")
    }
    
    // MARK: - stdio Server
    
    private func startStdioServer() async {
        logger.info("Starting stdio server")
        
        stdioTask = Task {
            // Read from stdin in a background task
            let inputHandle = FileHandle.standardInput
            let outputHandle = FileHandle.standardOutput
            
            while !Task.isCancelled {
                do {
                    // Read line from stdin
                    if let data = try await readLine(from: inputHandle), !data.isEmpty {
                        let _ = await MainActor.run {
                            Task { @MainActor in
                                await self.processStdioData(data, outputHandle: outputHandle)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.logger.error("stdio read error: \(error.localizedDescription)")
                    }
                    break
                }
            }
        }
    }
    
    private func readLine(from handle: FileHandle) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let data = handle.availableData
                continuation.resume(returning: data.isEmpty ? nil : data)
            }
        }
    }
    
    private func processStdioData(_ data: Data, outputHandle: FileHandle) async {
        logger.info("Received stdio data: \(data.count) bytes")
        
        // Log request for debugging
        onLog?("INFO", "Received stdio data: \(data.count) bytes", "SwiftMCPServer")
        
        // Parse incoming JSON-RPC request
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let method = json?["method"] as? String ?? "unknown"
            let idValue = json?["id"]
            let params = json?["params"] as? [String: Any]
            
            // For now, just log the request without creating complex types
            let requestInfo = ["method": method, "id": idValue as Any, "params": params as Any]
            onRequest?(requestInfo)
            
            // Create appropriate response based on method
            let response: [String: Any]
            
            switch method {
            case "initialize":
                response = createInitializeResponse(id: idValue)
            case "tools/list":
                response = createToolsListResponse(id: idValue)
            case "tools/call":
                response = createToolCallResponse(id: idValue, params: params)
            default:
                response = createErrorResponse(id: idValue, message: "Method not found: \(method)")
            }
            
            let responseData = try JSONSerialization.data(withJSONObject: response)
            sendStdioData(responseData, to: outputHandle)
            
            onResponse?(response)
            
        } catch {
            logger.error("Failed to process stdio request: \(error.localizedDescription)")
            onLog?("ERROR", "Failed to process stdio request: \(error.localizedDescription)", "SwiftMCPServer")
        }
    }
    
    private func sendStdioData(_ data: Data, to handle: FileHandle) {
        do {
            try handle.write(contentsOf: data)
            // Add newline separator for stdio
            try handle.write(contentsOf: Data([0x0A]))
        } catch {
            logger.error("Failed to send stdio data: \(error.localizedDescription)")
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) async {
        logger.info("New TCP connection")
        connections.append(connection)
        
        connection.start(queue: .main)
        
        // Handle incoming data
        receiveData(from: connection)
        
        // Handle connection state changes
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                await self?.handleConnectionStateChange(connection, state: state)
            }
        }
    }
    
    private func receiveData(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                if let data = data, !data.isEmpty {
                    await self?.processData(data, from: connection)
                }
                
                if !isComplete {
                    self?.receiveData(from: connection)
                }
            }
        }
    }
    
    private func processData(_ data: Data, from connection: NWConnection) async {
        logger.info("Received \(data.count) bytes")
        
        // Log request for debugging
        onLog?("INFO", "Received \(data.count) bytes", "SwiftMCPServer")
        
        // Parse incoming JSON-RPC request
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let method = json?["method"] as? String ?? "unknown"
            let idValue = json?["id"]
            let params = json?["params"] as? [String: Any]
            
            // For now, just log the request without creating complex types
            let requestInfo = ["method": method, "id": idValue as Any, "params": params as Any]
            onRequest?(requestInfo)
            
            // Create appropriate response based on method
            let response: [String: Any]
            
            switch method {
            case "initialize":
                response = createInitializeResponse(id: idValue)
            case "tools/list":
                response = createToolsListResponse(id: idValue)
            case "tools/call":
                response = createToolCallResponse(id: idValue, params: params)
            default:
                response = createErrorResponse(id: idValue, message: "Method not found: \(method)")
            }
            
            let responseData = try JSONSerialization.data(withJSONObject: response)
            sendData(responseData, to: connection)
            
            onResponse?(response)
            
        } catch {
            logger.error("Failed to process request: \(error.localizedDescription)")
            onLog?("ERROR", "Failed to process request: \(error.localizedDescription)", "SwiftMCPServer")
        }
    }
    
    private func createInitializeResponse(id: Any?) -> [String: Any] {
        return [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [:] as [String: Any],
                    "resources": [:] as [String: Any]
                ],
                "serverInfo": [
                    "name": "TaskNote Bridge Server",
                    "version": "1.0.0"
                ]
            ]
        ]
    }
    
    private func createToolsListResponse(id: Any?) -> [String: Any] {
        return [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "tools": [
                    [
                        "name": "bb7_add-todo",
                        "description": "Create a new task in Things 3",
                        "inputSchema": [
                            "type": "object",
                            "properties": [
                                "title": ["type": "string", "description": "The title of the todo"],
                                "notes": ["type": "string", "description": "Additional notes for the todo"]
                            ],
                            "required": ["title"]
                        ]
                    ]
                ]
            ]
        ]
    }
    
    private func createToolCallResponse(id: Any?, params: [String: Any]?) -> [String: Any] {
        let toolName = params?["name"] as? String ?? "unknown"
        let arguments = params?["arguments"] as? [String: Any] ?? [:]
        
        // Simple success response
        return [
            "jsonrpc": "2.0",
            "id": id as Any,
            "result": [
                "content": [
                    [
                        "type": "text",
                        "text": "Tool \(toolName) executed successfully with arguments: \(arguments)"
                    ]
                ],
                "isError": false
            ]
        ]
    }
    
    private func createErrorResponse(id: Any?, message: String) -> [String: Any] {
        return [
            "jsonrpc": "2.0",
            "id": id as Any,
            "error": [
                "code": -32601,
                "message": message
            ]
        ]
    }
    
    private func sendData(_ data: Data, to connection: NWConnection) {
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send data: \(error.localizedDescription)")
            }
        })
    }
    
    private func handleConnectionStateChange(_ connection: NWConnection, state: NWConnection.State) async {
        switch state {
        case .ready:
            logger.info("Connection ready")
        case .failed(let error):
            logger.error("Connection failed: \(error.localizedDescription)")
            connections.removeAll { $0 === connection }
        case .cancelled:
            logger.info("Connection cancelled")
            connections.removeAll { $0 === connection }
        default:
            break
        }
    }
}
