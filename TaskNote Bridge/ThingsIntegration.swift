import Foundation
import AppKit

/// Native Swift integration with Things 3 using URL schemes
struct ThingsIntegration {
    
    // MARK: - Add Todo
    
    /// Create a new task in Things 3
    static func addTodo(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw ThingsError.missingParameter("title")
        }
        
        var urlComponents = URLComponents(string: "things:///add")!
        var queryItems: [URLQueryItem] = []
        
        // Required parameter
        queryItems.append(URLQueryItem(name: "title", value: title))
        
        // Optional parameters
        if let notes = params["notes"] as? String {
            queryItems.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if let deadline = params["deadline"] as? String {
            // Validate date format
            if isValidDateFormat(deadline) {
                queryItems.append(URLQueryItem(name: "deadline", value: deadline))
            }
        }
        
        if let tags = params["tags"] as? [String] {
            let tagsString = tags.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "tags", value: tagsString))
        }
        
        if let when = params["when"] as? String {
            queryItems.append(URLQueryItem(name: "when", value: when))
        }
        
        if let checklistItems = params["checklist_items"] as? [String] {
            let checklistString = checklistItems.joined(separator: "\n")
            queryItems.append(URLQueryItem(name: "checklist", value: checklistString))
        }
        
        if let listTitle = params["list_title"] as? String {
            queryItems.append(URLQueryItem(name: "list", value: listTitle))
        }
        
        if let listId = params["list_id"] as? String {
            queryItems.append(URLQueryItem(name: "list-id", value: listId))
        }
        
        if let heading = params["heading"] as? String {
            queryItems.append(URLQueryItem(name: "heading", value: heading))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw ThingsError.invalidURL("Failed to construct Things URL")
        }
        
        // Execute the URL scheme
        let success = await openURL(url)
        
        if success {
            return [.text("Successfully created todo: \\(title)")]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Add Project
    
    /// Create a new project in Things 3
    static func addProject(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw ThingsError.missingParameter("title")
        }
        
        var urlComponents = URLComponents(string: "things:///add-project")!
        var queryItems: [URLQueryItem] = []
        
        // Required parameter
        queryItems.append(URLQueryItem(name: "title", value: title))
        
        // Optional parameters
        if let notes = params["notes"] as? String {
            queryItems.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if let areaTitle = params["area_title"] as? String {
            queryItems.append(URLQueryItem(name: "area", value: areaTitle))
        }
        
        if let areaId = params["area_id"] as? String {
            queryItems.append(URLQueryItem(name: "area-id", value: areaId))
        }
        
        if let tags = params["tags"] as? [String] {
            let tagsString = tags.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "tags", value: tagsString))
        }
        
        if let deadline = params["deadline"] as? String {
            if isValidDateFormat(deadline) {
                queryItems.append(URLQueryItem(name: "deadline", value: deadline))
            }
        }
        
        if let when = params["when"] as? String {
            queryItems.append(URLQueryItem(name: "when", value: when))
        }
        
        if let todos = params["todos"] as? [String] {
            let todosString = todos.joined(separator: "\n")
            queryItems.append(URLQueryItem(name: "to-dos", value: todosString))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw ThingsError.invalidURL("Failed to construct Things URL")
        }
        
        // Execute the URL scheme
        let success = await openURL(url)
        
        if success {
            var responseText = "Successfully created project: \\(title)"
            if let todos = params["todos"] as? [String], !todos.isEmpty {
                responseText += " with \\(todos.count) initial tasks"
            }
            return [.text(responseText)]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Search Todos
    
    /// Search for existing tasks in Things 3
    static func searchTodos(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let query = params["query"] as? String else {
            throw ThingsError.missingParameter("query")
        }
        
        var urlComponents = URLComponents(string: "things:///search")!
        urlComponents.queryItems = [URLQueryItem(name: "query", value: query)]
        
        guard let url = urlComponents.url else {
            throw ThingsError.invalidURL("Failed to construct Things search URL")
        }
        
        let success = await openURL(url)
        
        if success {
            return [.text("Opened Things 3 search for: \\(query)")]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3 search. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Show/Open Todo
    
    /// Open a specific todo in Things 3
    static func openTodo(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw ThingsError.missingParameter("title")
        }
        
        // Use search to find and open the todo
        var urlComponents = URLComponents(string: "things:///search")!
        urlComponents.queryItems = [URLQueryItem(name: "query", value: title)]
        
        guard let url = urlComponents.url else {
            throw ThingsError.invalidURL("Failed to construct Things search URL")
        }
        
        let success = await openURL(url)
        
        if success {
            return [.text("Opened Things 3 to show todo: \\(title)")]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Get Today's Tasks
    
    /// Show today's tasks in Things 3
    static func getToday(_ params: [String: Any]) async throws -> [MCPContent] {
        let url = URL(string: "things:///today")!
        
        let success = await openURL(url)
        
        if success {
            return [.text("Opened Things 3 Today view")]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Get Upcoming Tasks
    
    /// Show upcoming tasks in Things 3
    static func getUpcoming(_ params: [String: Any]) async throws -> [MCPContent] {
        let url = URL(string: "things:///upcoming")!
        
        let success = await openURL(url)
        
        if success {
            return [.text("Opened Things 3 Upcoming view")]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Get Anytime Tasks
    
    /// Show anytime tasks in Things 3
    static func getAnytime(_ params: [String: Any]) async throws -> [MCPContent] {
        let url = URL(string: "things:///anytime")!
        
        let success = await openURL(url)
        
        if success {
            return [.text("Opened Things 3 Anytime view")]
        } else {
            throw ThingsError.executionFailed("Failed to open Things 3. Make sure Things 3 is installed.")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Open a URL using the system default handler
    private static func openURL(_ url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let success = NSWorkspace.shared.open(url)
                continuation.resume(returning: success)
            }
        }
    }
    
    /// Validate date format (YYYY-MM-DD)
    private static func isValidDateFormat(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString) != nil
    }
}

// MARK: - Error Types

enum ThingsError: Error {
    case missingParameter(String)
    case invalidURL(String)
    case executionFailed(String)
}

extension ThingsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidURL(_):
            return "Invalid URL constructed"
        case .executionFailed(_):
            return "Execution of URL scheme failed"
        }
    }
}
