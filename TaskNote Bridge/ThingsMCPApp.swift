import SwiftUI
import Foundation
import OSLog

@main
struct ThingsMCPApp: App {
    
    init() {
        // Debug: Print all command line arguments
        print("DEBUG: Command line arguments: \(CommandLine.arguments)")
        print("DEBUG: Contains --stdio: \(CommandLine.arguments.contains("--stdio"))")
        
        // Check for stdio mode from command line arguments
        if CommandLine.arguments.contains("--stdio") {
            print("DEBUG: Entering stdio mode")
            // Run in stdio mode for MCP clients like Claude Desktop
            runStdioModeSync()
        } else {
            print("DEBUG: Entering GUI mode")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func runStdioModeSync() {
        let logger = Logger(subsystem: "com.tasknotebridge.app", category: "StdioMode")
        logger.info("Starting TaskNote Bridge MCP Server in stdio mode")
        
        // Create and start stdio server on a background thread to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                await StdioMCPServer.run()
                logger.info("Stdio mode completed")
                exit(0)
            }
        }
        
        // Exit the app after a brief delay to prevent SwiftUI initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Give stdio server time to start
            if CommandLine.arguments.contains("--stdio") {
                // Don't exit immediately, let the server run
                // The server will handle exit when it's done
            }
        }
    }
}
