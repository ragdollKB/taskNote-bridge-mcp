import Foundation

// Define AnyCodingKey to be used by AnyCodable for dictionary encoding
internal struct AnyCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\\(intValue)"
        self.intValue = intValue
    }
}

/**
 A type-erased wrapper for any `Codable` value.
 Stores `nil` as an empty tuple `()` internally.
 */
public struct AnyCodable: Equatable, Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        if let value = value {
            self.value = value
        } else {
            self.value = () // Internal nil sentinel
        }
    }

    // MARK: - Equatable

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is Void, is Void): // Both are internal nil sentinel
            return true
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Int8, let r as Int8):
            return l == r
        case (let l as Int16, let r as Int16):
            return l == r
        case (let l as Int32, let r as Int32):
            return l == r
        case (let l as Int64, let r as Int64):
            return l == r
        case (let l as UInt, let r as UInt):
            return l == r
        case (let l as UInt8, let r as UInt8):
            return l == r
        case (let l as UInt16, let r as UInt16):
            return l == r
        case (let l as UInt32, let r as UInt32):
            return l == r
        case (let l as UInt64, let r as UInt64):
            return l == r
        case (let l as Float, let r as Float):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as String, let r as String):
            return l == r
        case (let l as Date, let r as Date):
            return l == r
        case (let l as URL, let r as URL):
            return l == r
        case (let l as [AnyCodable], let r as [AnyCodable]):
            return l == r
        case (let l as [String: AnyCodable], let r as [String: AnyCodable]):
            return l == r
        default:
            // If types are different or not one of the above, they are not equal.
            // This also handles cases where one is nil (Void) and the other is not.
            return false
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = () // Store JSON null as our internal nil sentinel
            return
        }
        
        if let bool = try? container.decode(Bool.self) { self.value = bool }
        else if let int = try? container.decode(Int.self) { self.value = int }
        else if let int8 = try? container.decode(Int8.self) { self.value = int8 }
        else if let int16 = try? container.decode(Int16.self) { self.value = int16 }
        else if let int32 = try? container.decode(Int32.self) { self.value = int32 }
        else if let int64 = try? container.decode(Int64.self) { self.value = int64 }
        else if let uint = try? container.decode(UInt.self) { self.value = uint }
        else if let uint8 = try? container.decode(UInt8.self) { self.value = uint8 }
        else if let uint16 = try? container.decode(UInt16.self) { self.value = uint16 }
        else if let uint32 = try? container.decode(UInt32.self) { self.value = uint32 }
        else if let uint64 = try? container.decode(UInt64.self) { self.value = uint64 }
        else if let float = try? container.decode(Float.self) { self.value = float }
        else if let double = try? container.decode(Double.self) { self.value = double }
        else if let string = try? container.decode(String.self) { self.value = string }
        else if let date = try? container.decode(Date.self) { self.value = date }
        else if let url = try? container.decode(URL.self) { self.value = url }
        else if let array = try? container.decode([AnyCodable].self) { self.value = array }
        else if let dictionary = try? container.decode([String: AnyCodable].self) { self.value = dictionary }
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        if self.value is Void { // Check for internal nil sentinel ()
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }

        switch self.value {
        case is NSNull: // Should ideally not be stored if init converts nil to (), but handle anyway
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case let bool as Bool:
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case let int as Int:
            var container = encoder.singleValueContainer()
            try container.encode(int)
        case let int8 as Int8:
            var container = encoder.singleValueContainer()
            try container.encode(int8)
        case let int16 as Int16:
            var container = encoder.singleValueContainer()
            try container.encode(int16)
        case let int32 as Int32:
            var container = encoder.singleValueContainer()
            try container.encode(int32)
        case let int64 as Int64:
            var container = encoder.singleValueContainer()
            try container.encode(int64)
        case let uint as UInt:
            var container = encoder.singleValueContainer()
            try container.encode(uint)
        case let uint8 as UInt8:
            var container = encoder.singleValueContainer()
            try container.encode(uint8)
        case let uint16 as UInt16:
            var container = encoder.singleValueContainer()
            try container.encode(uint16)
        case let uint32 as UInt32:
            var container = encoder.singleValueContainer()
            try container.encode(uint32)
        case let uint64 as UInt64:
            var container = encoder.singleValueContainer()
            try container.encode(uint64)
        case let float as Float:
            var container = encoder.singleValueContainer()
            try container.encode(float)
        case let double as Double:
            var container = encoder.singleValueContainer()
            try container.encode(double)
        case let string as String:
            var container = encoder.singleValueContainer()
            try container.encode(string)
        case let date as Date:
            var container = encoder.singleValueContainer()
            try container.encode(date)
        case let url as URL:
            var container = encoder.singleValueContainer()
            try container.encode(url)
        case let array as [AnyCodable]: // Value is already [AnyCodable] (e.g., from decoder)
            var container = encoder.unkeyedContainer()
            try container.encode(contentsOf: array)
        case let dictionary as [String: AnyCodable]: // Value is already [String: AnyCodable]
            var container = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in dictionary {
                let codingKey = AnyCodingKey(stringValue: key)! // Assume key is valid
                try container.encode(value, forKey: codingKey)
            }
        case let array as [Any?]: // Value is a raw array like [Int], [String?], etc.
            var container = encoder.unkeyedContainer()
            try container.encode(contentsOf: array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]: // Value is a raw dictionary like [String: Int]
            var container = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in dictionary {
                let codingKey = AnyCodingKey(stringValue: key)! // Assume key is valid
                try container.encode(AnyCodable(value), forKey: codingKey)
            }
        default:
            let container = encoder.singleValueContainer()
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value \\(self.value) of type \\(type(of: self.value)) is not encodable by this AnyCodable implementation.")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}

// MARK: - MCP Protocol Structures

/// Minimal request structure for extracting just the ID
public struct MCPRequestMinimal: Codable {
    public let id: AnyCodable?
    public let method: String?
    
    public enum CodingKeys: String, CodingKey {
        case id, method
    }
}

/// JSON-RPC 2.0 base message structure
public protocol MCPMessage: Codable {
    var jsonrpc: String { get }
    var id: AnyCodable? { get }
}

/// JSON-RPC 2.0 Request
public struct MCPRequest: MCPMessage {
    public let jsonrpc: String
    public let id: AnyCodable?
    public let method: String
    public let params: AnyCodable? // Params can be an object or an array, or nil

    public enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }
    
    public init(id: AnyCodable? = nil, method: String, params: AnyCodable? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }

    // Custom Codable conformance is handled by AnyCodable for params
}

/**
 Represents an error in the MCP process.
 Conforms to Swift\'s Error and LocalizedError for better integration.
 */
public struct MCPError: Error, Codable, Equatable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?

    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    // Standard JSON-RPC Error Codes
    public static func parseError(data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32700, message: "Parse error", data: data)
    }
    public static func invalidRequest(data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32600, message: "Invalid Request", data: data)
    }
    public static func methodNotFound(methodName: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32601, message: "Method not found: \\(methodName)", data: data)
    }
    public static func invalidParams(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32602, message: "Invalid params: \\(details)", data: data)
    }
    public static func internalError(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32603, message: "Internal error: \\(details)", data: data)
    }

    // MCP-Specific Error Codes (starting from -32000)
    public static func serverError(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32000, message: "Server error: \\(details)", data: data)
    }
    public static func invalidToolName(toolName: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32001, message: "Invalid tool name: \\(toolName)", data: data)
    }
    public static func invalidResourceURI(uri: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32002, message: "Invalid resource URI: \\(uri)", data: data)
    }
    public static func resourceNotFound(uri: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32003, message: "Resource not found: \\(uri)", data: data)
    }
    public static func toolExecutionFailed(toolName: String, details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32004, message: "Tool execution failed for \\(toolName): \\(details)", data: data)
    }
    public static func permissionDenied(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32005, message: "Permission denied: \\(details)", data: data)
    }
    public static func resourceReadFailed(uri: String, details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32006, message: "Failed to read resource \\(uri): \\(details)", data: data)
    }
    public static func promptNotFound(promptName: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32007, message: "Prompt not found: \\(promptName)", data: data)
    }
    public static func configurationError(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32008, message: "Configuration error: \\(details)", data: data)
    }
    public static func networkError(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32009, message: "Network error: \\(details)", data: data)
    }
    public static func timeoutError(details: String, data: AnyCodable? = nil) -> MCPError {
        MCPError(code: -32010, message: "Timeout error: \\(details)", data: data)
    }
}

// Implement LocalizedError for MCPError
extension MCPError: LocalizedError {
    public var errorDescription: String? {
        return self.message
    }

    public var failureReason: String? {
        return self.message
    }

    public var recoverySuggestion: String? {
        switch code {
        case -32700:
            return "Ensure the request is valid JSON."
        case -32600:
            return "Check the request structure and ensure all required fields are present."
        case -32601:
            return "Verify the method name is correct and supported by the server."
        case -32602:
            return "Check the parameters for the method and ensure they match the expected schema."
        default:
            return "Please check the server logs for more details or contact support."
        }
    }

    public var helpAnchor: String? {
        return "For more information on MCP error codes, please refer to the protocol documentation."
    }
}

/// JSON-RPC 2.0 Response
public struct MCPResponse: MCPMessage {
    public let jsonrpc: String
    public let id: AnyCodable?
    public let result: AnyCodable?
    public let error: MCPError?

    public init(id: AnyCodable?, result: AnyCodable?, error: MCPError? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }

    // Convenience initializer for success
    public static func success(id: AnyCodable?, result: AnyCodable?) -> MCPResponse {
        return MCPResponse(id: id, result: result, error: nil)
    }

    // Convenience initializer for error
    public static func failure(id: AnyCodable?, error: MCPError) -> MCPResponse {
        return MCPResponse(id: id, result: nil, error: error)
    }
}

// MARK: - Tool Definition Structures (Example)

public struct MCPToolInfo: Codable, Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let description: String
    public let inputSchema: [String: String]? // Simplified schema for example

    public init(name: String, description: String, inputSchema: [String: String]? = nil) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

// MARK: - Initialize Method Structures

public struct ClientInfo: Codable, Equatable {
    let name: String
    let version: String
    // Add other relevant client information fields
}

public struct ServerInfo: Codable, Equatable {
    let name: String
    let version: String
    let mcpVersion: String?
    // Add other relevant server information fields
}

public struct MCPInitializeRequestParams: Codable, Equatable {
    let protocolVersion: String
    let clientInfo: ClientInfo
    // let capabilities: ClientCapabilities? // Define if needed
}

public struct MCPInitializeResult: Codable, Equatable {
    let protocolVersion: String
    let serverInfo: ServerInfo
    let tools: [MCPToolInfo]? // List of available tools
    // let capabilities: ServerCapabilities // Define ServerCapabilities struct
}

// MARK: - Tool Call Structures

public struct MCPToolCallParams: Codable, Equatable {
    let name: String
    let arguments: AnyCodable? // Arguments can be complex
}

// This is the content that a tool returns, which can be a single item or an array of items.
// It's designed to be flexible.
public struct MCPContent: Codable, Equatable {
    let type: String // e.g., "text", "image", "file", "json"
    let text: String?
    let data: Data? // For binary data like images
    let mimeType: String? // e.g., "image/png", "application/json"
    let uri: String? // For file references or URLs
    // Add other common fields as needed, or use a nested AnyCodable for 'details'

    public init(type: String, text: String? = nil, data: Data? = nil, mimeType: String? = nil, uri: String? = nil) {
        self.type = type
        self.text = text
        self.data = data
        self.mimeType = mimeType
        self.uri = uri
    }

    // Convenience initializers
    public static func text(_ text: String) -> MCPContent {
        return MCPContent(type: "text", text: text)
    }

    public static func json(_ jsonObject: any Codable) -> MCPContent {
        // Attempt to encode the JSON object to a string
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Optional: for readability
        do {
            let jsonData = try encoder.encode(jsonObject)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return MCPContent(type: "json", text: jsonString, mimeType: "application/json")
        } catch {
            // Fallback if encoding fails
            return MCPContent(type: "text", text: "Error encoding JSON: \\(error.localizedDescription)")
        }
    }
}


public struct MCPToolCallResult: Codable, Equatable {
    // The primary content of the tool's result. Can be a single MCPContent item
    // or an array of MCPContent items, wrapped in AnyCodable for flexibility.
    // If a tool returns a simple string, it should be wrapped in MCPContent.text().
    // If a tool returns a list of items, it should be [MCPContent] and then wrapped in AnyCodable.
    let content: AnyCodable // This will typically be AnyCodable([MCPContent]) or AnyCodable(MCPContent)
    let isError: Bool? // Optional: indicates if the tool itself considers this an error
    let rawOutput: String? // Optional: raw output from the tool

    public init(content: AnyCodable, isError: Bool? = nil, rawOutput: String? = nil) {
        self.content = content
        self.isError = isError
        self.rawOutput = rawOutput
    }

    // Convenience for single text content
    public static func success(text: String, id: AnyCodable?) -> MCPResponse {
        let mcpContent = MCPContent.text(text)
        let toolResult = MCPToolCallResult(content: AnyCodable(mcpContent))
        return MCPResponse.success(id: id, result: AnyCodable(toolResult))
    }

    // Convenience for multiple content items
    public static func success(contents: [MCPContent], id: AnyCodable?) -> MCPResponse {
        let toolResult = MCPToolCallResult(content: AnyCodable(contents))
        return MCPResponse.success(id: id, result: AnyCodable(toolResult))
    }
    
    // Convenience for a single MCPContent item
    public static func success(contentItem: MCPContent, id: AnyCodable?) -> MCPResponse {
        let toolResult = MCPToolCallResult(content: AnyCodable(contentItem))
        return MCPResponse.success(id: id, result: AnyCodable(toolResult))
    }
}

// MARK: - Resource Structures (Example)

public struct MCPResourceInfo: Codable, Identifiable, Equatable {
    public var id: String { uri }
    let uri: String
    let name: String?
    let description: String?
    let mimeType: String?
}

public struct MCPResourceReadParams: Codable, Equatable {
    let uri: String
}

public struct MCPResourceReadResultContent: Codable, Equatable {
    let uri: String
    let text: String?
    let binary: Data? // For binary resources
    let mimeType: String?
}

public struct MCPResourceReadResult: Codable, Equatable {
    let contents: [MCPResourceReadResultContent]
}

// MARK: - Prompt Structures (Example)

public struct MCPPromptInfoArgument: Codable, Equatable {
    let name: String
    let description: String?
    let required: Bool?
    let type: String? // e.g., "string", "number", "boolean"
}

public struct MCPPromptInfo: Codable, Identifiable, Equatable {
    public var id: String { name }
    let name: String
    let description: String?
    let arguments: [MCPPromptInfoArgument]?
}

public struct MCPPromptGetParams: Codable, Equatable {
    let name: String
    let arguments: AnyCodable? // Arguments for the prompt template
}

public struct MCPPromptGetResultMessageContent: Codable, Equatable {
    // Define structure for message content if it's more complex than just text
    // For example, if it can include images, resources, etc.
    let type: String // e.g., "text", "image_url", "resource_ref"
    let text: String?
    // Add other fields as necessary based on content type
}


public struct MCPPromptGetResultMessage: Codable, Equatable {
    let role: String // e.g., "user", "assistant", "system"
    let content: MCPPromptGetResultMessageContent // Or AnyCodable if highly variable
}

public struct MCPPromptGetResult: Codable, Equatable {
    let description: String?
    let messages: [MCPPromptGetResultMessage]
}

// MARK: - Additional Types for Server Implementation

public struct MCPSchema: Codable, Equatable {
    let type: String
    let properties: [String: MCPProperty]?
    let required: [String]?
    
    init(type: String, properties: [String: MCPProperty]? = nil, required: [String]? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
    }
}

public indirect enum MCPProperty: Codable, Equatable {
    case string(description: String?)
    case array(description: String?, items: MCPProperty?)
    case object(description: String?, properties: [String: MCPProperty]?, required: [String]?)
    case number(description: String?)
    case boolean(description: String?)
    
    init(type: String, description: String? = nil, items: MCPProperty? = nil, properties: [String: MCPProperty]? = nil, required: [String]? = nil) {
        switch type {
        case "string":
            self = .string(description: description)
        case "array":
            self = .array(description: description, items: items)
        case "object":
            self = .object(description: description, properties: properties, required: required)
        case "number", "integer":
            self = .number(description: description)
        case "boolean":
            self = .boolean(description: description)
        default:
            self = .string(description: description)
        }
    }
}

public struct MCPToolDefinition: Codable, Equatable {
    let name: String
    let description: String
    let inputSchema: MCPSchema
    
    init(name: String, description: String, inputSchema: MCPSchema) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

// Basic TCP server type for extension
public class TCPServer {
    // Moved the enum outside to avoid conflicts
}

extension TCPServer {
    enum ServerState: Equatable {
        case idle
        case starting
        case running
        case stopping
        case stopped
        case error(String)

        var description: String {
            switch self {
            case .idle: return "Idle"
            case .starting: return "Starting"
            case .running: return "Running"
            case .stopping: return "Stopping"
            case .stopped: return "Stopped"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
}
