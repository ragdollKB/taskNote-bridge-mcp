import Foundation
import OSLog
import Network

/// Pure Swift MCP Server Implementation - Minimal Working Version
@MainActor
class SwiftMCPServer: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isRunning = false
    @Published var status = "Stopped"
    @Published var lastError: String?
    
    private let logger = Logger(subsystem: "things-mcp", category: "SwiftMCPServer")
    private var tcpListener: NWListener?
    private var connections: [NWConnection] = []
    
    private let port: UInt16 = 3001
    
    // MARK: - Lifecycle
    
    init() {
        logger.info("SwiftMCPServer initialized")
    }
    
    // MARK: - Server Control
    
    func start() async {
        guard !isRunning else {
            logger.warning("Server already running")
            return
        }
        
        do {
            try await startTCPServer()
            isRunning = true
            status = "Running on TCP port \(port)"
            lastError = nil
            logger.info("SwiftMCPServer started successfully")
        } catch {
            lastError = error.localizedDescription
            status = "Failed to start: \(error.localizedDescription)"
            logger.error("Failed to start server: \(error.localizedDescription)")
        }
    }
    
    func stop() async {
        guard isRunning else { return }
        
        tcpListener?.cancel()
        tcpListener = nil
        
        // Close all connections
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        
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
        
        // Simple MCP response stub
        let response = [
            "jsonrpc": "2.0",
            "id": 1,
            "result": [
                "capabilities": [
                    "tools": [:] as [String: Any],
                    "resources": [:] as [String: Any]
                ],
                "serverInfo": [
                    "name": "TaskNote Bridge Server",
                    "version": "1.0.0"
                ]
            ]
        ] as [String: Any]
        
        do {
            let responseData = try JSONSerialization.data(withJSONObject: response)
            sendData(responseData, to: connection)
        } catch {
            logger.error("Failed to create response: \(error.localizedDescription)")
        }
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
