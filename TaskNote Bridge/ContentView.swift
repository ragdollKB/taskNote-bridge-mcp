import SwiftUI

struct ContentView: View {
    @StateObject private var mcpService = MCPService()
    @State private var selectedTab = "status"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("TaskNote Bridge Server")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                List(selection: $selectedTab) {
                    Section("Server") {
                        Label("Status", systemImage: "circle.fill")
                            .foregroundColor(mcpService.isConnected ? .green : .red)
                            .tag("status")
                        
                        Label("Logs", systemImage: "text.alignleft")
                            .tag("logs")
                            
                        Label("Requests", systemImage: "arrow.left.arrow.right")
                            .tag("requests")
                            
                        Label("Settings", systemImage: "gear")
                            .tag("settings")
                    }
                    
                    Section("Tools") {
                        Label("MCP Tools", systemImage: "hammer")
                            .tag("tools")
                            
                        Label("Documentation", systemImage: "doc.text")
                            .tag("docs")
                    }
                }
                .listStyle(.sidebar)
            }
        } detail: {
            // Main content area
            VStack {
                switch selectedTab {
                case "status":
                    ServerStatusView(mcpService: mcpService)
                case "logs":
                    LogsView(logs: mcpService.logs, clearLogs: mcpService.clearLogs)
                case "requests":
                    RequestsView(requests: mcpService.requestDisplayModels)
                case "settings":
                    SettingsView(mcpService: mcpService)
                case "tools":
                    ToolsView(tools: mcpService.availableTools)
                case "docs":
                    DocumentationView()
                default:
                    ServerStatusView(mcpService: mcpService)
                }
            }
        }
        .onAppear {
            Task {
                await mcpService.connect()
                await mcpService.startServer()
            }
        }
    }
}

// Status view showing server health and statistics
struct ServerStatusView: View {
    @ObservedObject var mcpService: MCPService
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Server Status")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack {
                    if mcpService.isConnected {
                        Button("Stop Server") {
                            mcpService.disconnect()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button("Start Server") {
                            Task {
                                await mcpService.connect()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    StatusIndicator(isConnected: mcpService.isConnected)
                }
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 20) {
                StatusCard(
                    title: "MCP Server",
                    value: mcpService.isConnected ? "Running" : "Stopped",
                    color: mcpService.isConnected ? .green : .red,
                    icon: "server.rack"
                )
                
                StatusCard(
                    title: "Uptime",
                    value: mcpService.uptimeDisplay,
                    color: .blue,
                    icon: "clock"
                )
                
                StatusCard(
                    title: "Total Requests",
                    value: "\(mcpService.requests.count)",
                    color: .orange,
                    icon: "arrow.left.arrow.right"
                )
                
                HStack {
                    StatusCard(
                        title: "Things Tools",
                        value: "16 Tools",
                        color: .purple,
                        icon: "checklist"
                    )
                    
                    StatusCard(
                        title: "Notes Tools",
                        value: "12 Tools",
                        color: .yellow,
                        icon: "note.text"
                    )
                }
            }
            .padding()
            
            Spacer()
            
            // Server controls
            HStack {
                Spacer()
                
                Button(mcpService.isConnected ? "Stop Server" : "Start Server") {
                    Task {
                        if mcpService.isConnected {
                            mcpService.disconnect()
                        } else {
                            await mcpService.connect()
                            await mcpService.startServer()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(mcpService.isConnected ? .red : .green)
                
                Button("Restart Server") {
                    Task {
                        mcpService.disconnect()
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await mcpService.connect()
                        await mcpService.startServer()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!mcpService.isConnected)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatusIndicator: View {
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            Text(isConnected ? "Online" : "Offline")
                .foregroundColor(isConnected ? .green : .red)
                .font(.headline)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Missing View Implementations

struct LogsView: View {
    let logs: [LogEntry]
    let clearLogs: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Server Logs")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Clear") {
                    clearLogs()
                }
            }
            .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logs, id: \.id) { log in
                        HStack(alignment: .top, spacing: 8) {
                            Text(DateFormatter.timeFormatter.string(from: log.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            
                            Text("[\(log.level.rawValue)]")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(log.level.color)
                                .frame(width: 60, alignment: .leading)
                            
                            Text(log.message)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                    }
                }
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct RequestsView: View {
    let requests: [MCPRequestDisplayModel]
    
    var body: some View {
        VStack {
            Text("MCP Requests")
                .font(.title2)
                .fontWeight(.bold)
            
            if requests.isEmpty {
                Text("No requests yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(requests, id: \.toolName) { request in
                    VStack(alignment: .leading) {
                        Text(request.toolName)
                            .fontWeight(.semibold)
                        Text(request.parameters)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var mcpService: MCPService
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Section("Server Configuration") {
                    Toggle("Debug Logging", isOn: $mcpService.debugLogging)
                    Toggle("Enable Things Tools", isOn: $mcpService.enableThingsTools)
                    Toggle("Enable Notes Tools", isOn: $mcpService.enableNotesTools)
                }
            }
        }
    }
}

struct ToolsView: View {
    let tools: [MCPTool]
    
    var body: some View {
        VStack {
            Text("Available Tools")
                .font(.title2)
                .fontWeight(.bold)
            
            if tools.isEmpty {
                Text("No tools available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(tools, id: \.name) { tool in
                    VStack(alignment: .leading) {
                        Text(tool.name)
                            .fontWeight(.semibold)
                        Text(tool.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct DocumentationView: View {
    var body: some View {
        VStack {
            Text("Documentation")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Things 3 MCP Server")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("This is a Model Context Protocol (MCP) server that provides integration with Things 3 task management and Apple Notes.")
                    
                    Text("Available Tools:")
                        .fontWeight(.semibold)
                    
                    Text("• bb7_add-todo - Create tasks in Things 3\n• bb7_add-project - Create projects in Things 3\n• bb7_search-todos - Search for tasks\n• bb7_notes-create - Create notes in Apple Notes\n• bb7_notes-search - Search notes")
                        .font(.caption)
                }
                .padding()
            }
        }
    }
}

// MARK: - Helper Extensions

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

#Preview {
    ContentView()
}
