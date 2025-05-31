import Foundation
import SwiftUI

// MARK: - Server Models

// Log level enumeration
enum LogLevel: String, CaseIterable, Identifiable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .debug: return Color.gray
        case .info: return Color.blue
        case .warning: return Color.orange
        case .error: return Color.red
        }
    }
}

// Log entry model
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String
}

// MCP request display model
struct MCPRequestDisplayModel: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let toolName: String
    let parameters: String
    var response: String
    var duration: TimeInterval
    var status: String
    let clientName: String

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Conformance to Equatable (required by Hashable)
    static func == (lhs: MCPRequestDisplayModel, rhs: MCPRequestDisplayModel) -> Bool {
        lhs.id == rhs.id
    }
    
    var shortParameters: String {
        if parameters.count > 60 {
            return parameters.prefix(60) + "..."
        }
        return parameters
    }
    
    var isSuccess: Bool {
        status == "Success"
    }
}

// MCP tool parameter model
struct MCPParameter: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let description: String
    let required: Bool
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Conformance to Equatable (required by Hashable)
    static func == (lhs: MCPParameter, rhs: MCPParameter) -> Bool {
        lhs.id == rhs.id
    }
}

// MCP tool model
struct MCPTool: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let category: String
    let parameters: [MCPParameter]
    let example: String
    
    var parameterCount: Int {
        parameters.count
    }
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Conformance to Equatable (required by Hashable)
    static func == (lhs: MCPTool, rhs: MCPTool) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Data Models

// MARK: - Todo Item
struct TodoItem: Identifiable, Codable {
    let id: String
    var title: String
    var notes: String?
    var completed: Bool
    var deadline: Date?
    var tags: [String]
    var when: String? // today, tomorrow, evening, anytime, someday, or specific date
    var checklistItems: [ChecklistItem]
    var projectId: String?
    
    init(id: String, title: String, notes: String? = nil, completed: Bool = false, deadline: Date? = nil, tags: [String] = [], when: String? = nil, checklistItems: [ChecklistItem] = [], projectId: String? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.completed = completed
        self.deadline = deadline
        self.tags = tags
        self.when = when
        self.checklistItems = checklistItems
        self.projectId = projectId
    }
}

// MARK: - Project Item
struct ProjectItem: Identifiable, Codable {
    let id: String
    var title: String
    var notes: String?
    var completed: Bool
    var deadline: Date?
    var tags: [String]
    var areaId: String?
    var todos: [TodoItem]
    
    init(id: String, title: String, notes: String? = nil, completed: Bool = false, deadline: Date? = nil, tags: [String] = [], areaId: String? = nil, todos: [TodoItem] = []) {
        self.id = id
        self.title = title
        self.notes = notes
        self.completed = completed
        self.deadline = deadline
        self.tags = tags
        self.areaId = areaId
        self.todos = todos
    }
}

// MARK: - Note Item
struct NoteItem: Identifiable, Codable {
    let id: String
    var title: String
    var content: String
    var tags: [String]
    var createdDate: Date
    var modifiedDate: Date
    
    init(id: String, title: String, content: String, tags: [String] = [], createdDate: Date = Date(), modifiedDate: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
}

// MARK: - Checklist Item
struct ChecklistItem: Identifiable, Codable {
    let id: String
    var title: String
    var completed: Bool
    
    init(id: String, title: String, completed: Bool = false) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}

// MARK: - Area Item
struct AreaItem: Identifiable, Codable {
    let id: String
    var title: String
    var notes: String?
    var tags: [String]
    var projects: [ProjectItem]
    
    init(id: String, title: String, notes: String? = nil, tags: [String] = [], projects: [ProjectItem] = []) {
        self.id = id
        self.title = title
        self.notes = notes
        self.tags = tags
        self.projects = projects
    }
}
