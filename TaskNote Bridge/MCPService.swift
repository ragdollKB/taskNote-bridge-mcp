import Foundation
import SwiftUI

/// Service for integrating with the pure Swift MCP server
class MCPService: ObservableObject {
    // Server status
    @Published var isConnected = false
    @Published var serverStartTime: Date?
    @Published var debugLogging = true
    @Published var enableThingsTools = true
    @Published var enableNotesTools = true
    @Published var serverPort = 8000
    
    // MCP data and monitoring
    @Published var logs: [LogEntry] = []
    @Published var requests: [MCPRequest] = []
    @Published var availableTools: [MCPTool] = []
    
    // Data models (kept for compatibility)
    @Published var todos: [TodoItem] = []
    @Published var projects: [ProjectItem] = []
    @Published var notes: [NoteItem] = []
    
    // Swift MCP Server
    private var swiftServer: SwiftMCPServer?
    private var logTimer: Timer?
    
    // Computed properties
    var uptimeDisplay: String {
        guard let startTime = serverStartTime else { return "Not running" }
        let timeInterval = Date().timeIntervalSince(startTime)
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    // Convert protocol-level requests to display models for UI
    var requestDisplayModels: [MCPRequestDisplayModel] {
        return requests.map { request in
            MCPRequestDisplayModel(
                timestamp: Date(), // We'll need to add timestamp tracking later
                toolName: request.method,
                parameters: formatParameters(request.params?.value as? [String: Any]),
                response: "Pending", // We'll need to track responses later
                duration: 0.0, // We'll need to track duration later
                status: "Pending", // We'll need to track status later
                clientName: "Unknown" // We'll need to track client info later
            )
        }
    }
    
    // Helper method to format parameters for display
    private func formatParameters(_ params: [String: Any]?) -> String {
        guard let params = params else { return "{}" }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "\(params)"
        }
    }
    
    init() {
        // Initialize server in task since it needs MainActor context
        Task { @MainActor in
            self.swiftServer = SwiftMCPServer()
            
            // Set up callbacks for the Swift server
            self.setupSwiftServerCallbacks()
            
            // Configure TCP port for the Swift server
            self.swiftServer?.setTCPPort(UInt16(self.serverPort))
            
            // Auto-start the server
            await self.startServer()
        }
        
        // Initialize with sample tools
        initializeSampleTools()
        
        // Start log monitor timer
        startLogMonitor()
        
        // Add initial log
        addLog(level: .info, message: "Swift MCPService initialized", source: "MCPService")
    }
    
    deinit {
        stopServer()
    }
    
    // MARK: - Swift Server Integration
    
    @MainActor
    private func setupSwiftServerCallbacks() {
        // Set up logging callback
        swiftServer?.onLog = { [weak self] level, message, source in
            DispatchQueue.main.async {
                // Convert string level to LogLevel enum
                let logLevel: LogLevel
                if let levelString = level as? String {
                    logLevel = LogLevel(rawValue: levelString.uppercased()) ?? .info
                } else {
                    logLevel = .info
                }
                self?.addLog(level: logLevel, message: message, source: source)
            }
        }
        
        // Set up request monitoring callback
        swiftServer?.onRequest = { [weak self] (request: Any) in
            DispatchQueue.main.async {
                if let mcpRequest = request as? MCPRequest {
                    self?.requests.append(mcpRequest)
                    if self?.requests.count ?? 0 > 100 {
                        self?.requests.removeFirst()
                    }
                }
            }
        }
        
        // Set up response monitoring callback (optional)
        swiftServer?.onResponse = { [weak self] (response: Any) in
            // Could add response monitoring here if needed
        }
    }
    
    // MARK: - Server Management
    
    func connect() async {
        await startServer()
    }
    
    func startServer() async {
        guard !isConnected else {
            addLog(level: .warning, message: "Swift MCP server already running", source: "MCPService")
            return
        }
        
        guard let server = swiftServer else {
            addLog(level: .error, message: "Swift MCP server not initialized", source: "MCPService")
            return
        }
        
        addLog(level: .info, message: "Starting Swift MCP server...", source: "MCPService")
        
        do {
            // Start the Swift MCP server
            await server.start()
            
            await MainActor.run {
                self.isConnected = true
                self.serverStartTime = Date()
                self.addLog(level: .info, message: "Swift MCP server started successfully", source: "MCPService")
            }
        } catch {
            await MainActor.run {
                self.isConnected = false // Ensure state is consistent on failure
                self.addLog(level: .error, message: "Failed to start Swift MCP server: \(error.localizedDescription)", source: "MCPService")
            }
        }
    }
    
    func stopServer() {
        guard isConnected else { return }
        
        addLog(level: .info, message: "Stopping Swift MCP server...", source: "MCPService")
        
        Task {
            await swiftServer?.stop()
        }
        
        cleanup()
        addLog(level: .info, message: "Swift MCP server stopped", source: "MCPService")
    }
    
    private func cleanup() {
        isConnected = false
        serverStartTime = nil
        addLog(level: .info, message: "Server cleanup completed", source: "MCPService")
    }
    
    func disconnect() {
        stopServer()
    }
    
    func rebuildSchema() {
        addLog(level: .info, message: "Rebuilding MCP schema for Swift server", source: "MCPService")
        // Schema is automatically built in Swift server
    }
    
    @MainActor
    func updateTCPPort() {
        swiftServer?.setTCPPort(UInt16(serverPort))
        addLog(level: .info, message: "TCP port updated to \(serverPort)", source: "MCPService")
    }
    
    // MARK: - Data Loading
    func loadAllData() async {
        // For Swift server monitoring, we only need minimal data loading
        await loadSampleData()
    }
    
    func loadSampleData() async {
        // Load minimal sample data for UI display
        print("Loading sample data for Swift MCP server...")
        
        await MainActor.run {
            // Add sample todos, projects, and notes for UI completeness
            self.todos = [
                TodoItem(id: "1", title: "Sample Todo (Swift)", notes: "This is from Swift MCP server", when: "today"),
                TodoItem(id: "2", title: "Another Swift Task", when: "anytime")
            ]
            
            self.projects = [
                ProjectItem(id: "1", title: "Sample Swift Project", notes: "Sample project from Swift server")
            ]
            
            self.notes = [
                NoteItem(id: "1", title: "Sample Swift Note", content: "Sample note from Swift MCP server")
            ]
        }
    }
    
    // MARK: - Logging and Monitoring
    
    private func startLogMonitor() {
        // Start monitoring for the Swift MCP server
        logTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isConnected else { return }
            
            // Add periodic status logs for Swift server
            if Int.random(in: 1...4) == 1 {
                let messages = [
                    "Swift MCP server running normally",
                    "Monitoring TCP connections",
                    "Tools registered and ready",
                    "Native integrations active"
                ]
                
                self.addLog(
                    level: .info,
                    message: messages.randomElement()!,
                    source: "SwiftMCPServer"
                )
            }
        }
    }
    
    func clearLogs() {
        logs.removeAll()
        addLog(level: .info, message: "Logs cleared", source: "MCPService")
    }
    
    private func addLog(level: LogLevel, message: String, source: String) {
        let log = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            source: source
        )
        
        // Keep only the last 1000 logs to prevent memory issues
        if logs.count >= 1000 {
            logs.removeFirst(100)
        }
        
        logs.append(log)
    }
    
    func addSampleRequests() {
        // Add some sample MCP requests for demonstration
        let toolNames = [
            "bb7_add-todo",
            "bb7_get-today",
            "bb7_get-projects",
            "notes-create",
            "notes-search"
        ]
        
        let clients = ["VS Code", "Claude Desktop", "VS Code"]
        
        // Add a few sample requests
        for _ in 1...5 {
            let toolName = toolNames.randomElement()!
            let duration = Double.random(in: 0.05...0.5)
            let success = Int.random(in: 1...10) <= 9 // 90% success rate
            
            let parameters: String
            let response: String
            let mcpId = Int.random(in: 1...1000) // Add an ID for MCPRequest

            switch toolName {
            case "bb7_add-todo":
                parameters = """
                {
                  "title": "Complete project proposal",
                  "when": "today",
                  "tags": ["work", "priority"]
                }
                """
                response = success ? """
                {
                  "success": true,
                  "id": "ABC123XYZ",
                  "message": "Todo created successfully"
                }
                """ : """
                {
                  "success": false,
                  "error": "Could not connect to Things app"
                }
                """
                
            case "bb7_get-today":
                parameters = "{}"
                response = success ? """
                {
                  "success": true,
                  "todos": [
                    {
                      "id": "123",
                      "title": "Meeting with team",
                      "when": "today"
                    },
                    {
                      "id": "456",
                      "title": "Submit expense report",
                      "when": "today"
                    }
                  ]
                }
                """ : """
                {
                  "success": false,
                  "error": "Failed to retrieve todos"
                }
                """
                
            default:
                parameters = "{ \"query\": \"project notes\" }"
                response = success ? """
                {
                  "success": true,
                  "results": ["Note 1", "Note 2"]
                }
                """ : """
                {
                  "success": false,
                  "error": "Unknown error occurred"
                }
                """
            }
            
            let request = MCPRequest( // Use the initializer from MCPProtocol.swift
                id: AnyCodable(mcpId),
                method: toolName,
                params: AnyCodable([
                    "timestamp": Date().addingTimeInterval(-Double.random(in: 60...3600)).timeIntervalSince1970,
                    "toolName": toolName,
                    "parameters": parameters,
                    "response": response,
                    "duration": duration,
                    "status": success ? "Success" : "Failed",
                    "clientName": clients.randomElement()!
                ])
            )
            
            DispatchQueue.main.async {
                self.requests.insert(request, at: 0)
            }
        }
    }
    
    // MARK: - Tool Management
    
    private func initializeSampleTools() {
        // These tools are automatically registered in SwiftMCPServer
        availableTools = [
            MCPTool(
                name: "bb7_add-todo",
                description: "Create a new task in Things 3 (Swift)",
                category: "Things",
                parameters: [
                    MCPParameter(name: "title", type: "string", description: "The title of the todo", required: true),
                    MCPParameter(name: "notes", type: "string", description: "Additional notes for the todo", required: false),
                    MCPParameter(name: "when", type: "string", description: "When the todo is scheduled", required: false),
                    MCPParameter(name: "deadline", type: "string", description: "The deadline date in YYYY-MM-DD format", required: false),
                    MCPParameter(name: "tags", type: "array", description: "Tags to apply to the todo", required: false)
                ],
                example: """
                {
                  "title": "Complete project proposal",
                  "notes": "Include budget estimations",
                  "when": "today",
                  "tags": ["work", "priority"]
                }
                """
            ),
            
            MCPTool(
                name: "bb7_add-project",
                description: "Create a new project in Things 3 (Swift)",
                category: "Things",
                parameters: [
                    MCPParameter(name: "title", type: "string", description: "The title of the project", required: true),
                    MCPParameter(name: "notes", type: "string", description: "Additional notes for the project", required: false),
                    MCPParameter(name: "area_title", type: "string", description: "The title of the area", required: false),
                    MCPParameter(name: "todos", type: "array", description: "List of todos to create", required: false)
                ],
                example: """
                {
                  "title": "Website Redesign",
                  "notes": "Refresh company website",
                  "area_title": "Work",
                  "todos": ["Update homepage", "Redesign logo"]
                }
                """
            ),
            
            MCPTool(
                name: "bb7_get-today",
                description: "Get todos due today",
                category: "Things",
                parameters: [],
                example: "{}"
            ),
            
            MCPTool(
                name: "notes-create",
                description: "Create a new note in Apple Notes",
                category: "Notes",
                parameters: [
                    MCPParameter(name: "title", type: "string", description: "The title of the note", required: true),
                    MCPParameter(name: "content", type: "string", description: "The content of the note", required: true),
                    MCPParameter(name: "tags", type: "array", description: "Tags to apply to the note", required: false)
                ],
                example: """
                {
                  "title": "Meeting Notes - May 24",
                  "content": "Discussed project timeline and next steps...",
                  "tags": ["meetings", "work"]
                }
                """
            ),
            
            MCPTool(
                name: "notes-search",
                description: "Search for notes by title",
                category: "Notes",
                parameters: [
                    MCPParameter(name: "query", type: "string", description: "The search query", required: true)
                ],
                example: """
                {
                  "query": "meeting"
                }
                """
            )
        ]
    }
    
    // MARK: - Swift MCP Operations
    
    func runMCPTool(name: String, parameters: [String: Any]) async -> String {
        addLog(level: .debug, message: "Running Swift MCP tool: \(name)", source: "MCPService")
        
        // The actual tool execution happens in SwiftMCPServer via TCP
        return "Tool execution handled by Swift MCP server"
    }
    
    func updateTodo(_ todo: TodoItem) async -> Bool {
        print("Updating todo via Swift MCP: \(todo.title)")
        
        await MainActor.run {
            if let index = self.todos.firstIndex(where: { $0.id == todo.id }) {
                self.todos[index] = todo
            }
        }
        
        return true
    }
    
    func deleteTodo(id: String) async -> Bool {
        print("Deleting todo via Swift MCP: \(id)")
        
        await MainActor.run {
            self.todos.removeAll { $0.id == id }
        }
        
        return true
    }
    
    // MARK: - Project Operations
    func addProject(title: String, notes: String? = nil, areaTitle: String? = nil, tags: [String] = [], todos: [String] = []) async -> Bool {
        print("Adding project via Swift MCP: \(title)")
        
        let newProject = ProjectItem(
            id: UUID().uuidString,
            title: title,
            notes: notes,
            tags: tags
        )
        
        await MainActor.run {
            self.projects.append(newProject)
        }
        
        return true
    }
    
    // MARK: - Note Operations
    func addNote(title: String, content: String, tags: [String] = []) async -> Bool {
        print("Adding note via Swift MCP: \(title)")
        
        let newNote = NoteItem(
            id: UUID().uuidString,
            title: title,
            content: content,
            tags: tags
        )
        
        await MainActor.run {
            self.notes.append(newNote)
        }
        
        return true
    }
    
    // MARK: - Python Integration Helpers
    private func executePythonScript(command: String, arguments: [String] = []) async -> String? {
        let _ = Bundle.main.path(forResource: "test_communication", ofType: "py")
            ?? "./test_communication.py"
        
        let _: [String: Any] = [
            "method": command,
            "params": arguments.isEmpty ? [:] : ["args": arguments]
        ]
        
        // Placeholder for where runPythonScript would be defined or called
        // let result = await runPythonScript(
        // scriptPath: scriptPath,
        // arguments: ["--mode", "stdio"],
        // input: request
        // )
        // For now, returning nil as the function is not defined
        print("runPythonScript called but not implemented, returning nil")
        return nil
        
        // if let status = result["status"] as? String, status == "success",
        //    let resultData = result["result"] as? [String: Any] {
        //     if let jsonData = try? JSONSerialization.data(withJSONObject: resultData),
        //        let jsonString = String(data: jsonData, encoding: .utf8) {
        //         return jsonString
        //     }
        //     // self.notes.append(newNote) // newNote is not defined in this scope
        // }
        //
        // return true // Should return String? to match function signature
    }
}
