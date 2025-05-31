import Foundation
import OSAKit

/// Native Swift integration with Apple Notes using AppleScript
struct NotesIntegration {
    
    // MARK: - Create Note
    
    /// Create a new note in Apple Notes
    static func createNote(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw NotesError.missingParameter("title")
        }
        
        guard let content = params["content"] as? String else {
            throw NotesError.missingParameter("content")
        }
        
        // Create the note content with title and body
        let fullContent = "\(title)\n\n\(content)"
        
        // AppleScript to create a note
        let script = """
        tell application "Notes"
            activate
            tell account "iCloud"
                make new note with properties {name:"\(title)", body:"\(escapeForAppleScript(fullContent))"}
            end tell
        end tell
        """
        
        let result = try await executeAppleScript(script)
        
        return [.text("Successfully created note: \\(title)")]
    }
    
    // MARK: - Search Notes
    
    /// Search for notes by title in Apple Notes
    static func searchNotes(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let query = params["query"] as? String else {
            throw NotesError.missingParameter("query")
        }
        
        let script = """
        tell application "Notes"
            activate
            set searchResults to {}
            tell account "iCloud"
                repeat with theNote in notes
                    if name of theNote contains "\\(escapeForAppleScript(query))" then
                        set end of searchResults to name of theNote
                    end if
                end repeat
            end tell
            return searchResults
        end tell
        """
        
        let result = try await executeAppleScript(script)
        
        if let resultString = result as? String, !resultString.isEmpty {
            return [.text("Found notes matching '\\(query)': \\(resultString)")]
        } else {
            return [.text("No notes found matching '\\(query)'")]
        }
    }
    
    // MARK: - Get Note Content
    
    /// Get the content of a specific note from Apple Notes
    static func getNoteContent(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw NotesError.missingParameter("title")
        }
        
        let script = """
        tell application "Notes"
            tell account "iCloud"
                repeat with theNote in notes
                    if name of theNote is "\\(escapeForAppleScript(title))" then
                        return body of theNote
                    end if
                end repeat
            end tell
            return "Note not found"
        end tell
        """
        
        let result = try await executeAppleScript(script)
        
        if let content = result as? String {
            return [.text("Content of '\\(title)': \\(content)")]
        } else {
            return [.text("Note '\\(title)' not found")]
        }
    }
    
    // MARK: - List Notes
    
    /// List all notes in Apple Notes
    static func listNotes(_ params: [String: Any]) async throws -> [MCPContent] {
        let script = """
        tell application "Notes"
            tell account "iCloud"
                set noteList to {}
                repeat with theNote in notes
                    set end of noteList to name of theNote
                end repeat
                return noteList
            end tell
        end tell
        """
        
        let result = try await executeAppleScript(script)
        
        if let noteList = result as? String {
            return [.text("Notes: \\(noteList)")]
        } else {
            return [.text("No notes found")]
        }
    }
    
    // MARK: - Open Note
    
    /// Open a note in Apple Notes app
    static func openNote(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw NotesError.missingParameter("title")
        }
        
        let script = """
        tell application "Notes"
            activate
            tell account "iCloud"
                repeat with theNote in notes
                    if name of theNote is "\\(escapeForAppleScript(title))" then
                        show theNote
                        return "Note opened"
                    end if
                end repeat
            end tell
            return "Note not found"
        end tell
        """
        
        let result = try await executeAppleScript(script)
        
        if let resultString = result as? String, resultString.contains("opened") {
            return [.text("Opened note: \\(title)")]
        } else {
            return [.text("Note '\\(title)' not found")]
        }
    }
    
    // MARK: - Delete Note
    
    /// Delete a note from Apple Notes
    static func deleteNote(_ params: [String: Any]) async throws -> [MCPContent] {
        guard let title = params["title"] as? String else {
            throw NotesError.missingParameter("title")
        }
        
        let script = """
        tell application "Notes"
            tell account "iCloud"
                repeat with theNote in notes
                    if name of theNote is "\\(escapeForAppleScript(title))" then
                        delete theNote
                        return "Note deleted"
                    end if
                end repeat
            end tell
            return "Note not found"
        end tell
        """
        
        let result = try await executeAppleScript(script)
        
        if let resultString = result as? String, resultString.contains("deleted") {
            return [.text("Deleted note: \\(title)")]
        } else {
            return [.text("Note '\\(title)' not found")]
        }
    }
    
    // MARK: - Helper Methods
    
    /// Execute AppleScript asynchronously
    private static func executeAppleScript(_ script: String) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let appleScript = OSAScript(source: script, language: OSALanguage(forName: "AppleScript"))
                    var error: NSDictionary?
                    let resultDescriptor = appleScript.executeAndReturnError(&error)
                    
                    if let error = error {
                        let errorDescription = error["OSAScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
                        continuation.resume(throwing: NotesError.scriptError(errorDescription))
                    } else {
                        // Safely unwrap the resultDescriptor and access stringValue
                        if let stringValue = resultDescriptor?.stringValue {
                            continuation.resume(returning: stringValue)
                        } else {
                            // Handle cases where stringValue is nil, perhaps by returning nil
                            // or a specific empty string, or throwing a different error.
                            // For now, returning nil if stringValue is not available.
                            continuation.resume(returning: nil)
                        }
                    }
                } catch {
                    continuation.resume(throwing: NotesError.scriptError(error.localizedDescription))
                }
            }
        }
    }
    
    /// Escape strings for safe use in AppleScript
    private static func escapeForAppleScript(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\") // Escape backslashes
            .replacingOccurrences(of: "\"", with: "\\\"")   // Escape double quotes
            .replacingOccurrences(of: "\n", with: "\\n") // Escape newlines
            .replacingOccurrences(of: "\r", with: "\\r") // Escape carriage returns
    }
}

// MARK: - Error Types

enum NotesError: Error {
    case missingParameter(String)
    case scriptError(String)
    case notFound(String)
}

extension NotesError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \\(param)"
        case .scriptError(let message):
            return "AppleScript error: \\(message)"
        case .notFound(let item):
            return "Not found: \\(item)"
        }
    }
}
