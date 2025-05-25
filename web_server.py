#!/usr/bin/env python3
"""
Simple HTTP server to handle MCP requests from the web interface.
This allows the HTML interface to communicate with the MCP server.
"""
import asyncio
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import sys
import os

# Add the current directory to Python path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from handlers import handle_tool_call

class MCPHTTPHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests - serve the HTML interface"""
        if self.path == '/' or self.path == '/index.html':
            self.serve_file('things3-mcp-interface.html', 'text/html')
        elif self.path == '/status':
            self.send_json_response({'status': 'ok', 'message': 'MCP server is running'})
        else:
            self.send_error(404)
    
    def do_POST(self):
        """Handle POST requests - MCP tool calls"""
        if self.path == '/api/mcp':
            self.handle_mcp_request()
        else:
            self.send_error(404)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
    
    def send_cors_headers(self):
        """Send CORS headers to allow cross-origin requests"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
    
    def serve_file(self, filename, content_type):
        """Serve a static file"""
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                content = f.read()
            
            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.send_cors_headers()
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
        except FileNotFoundError:
            self.send_error(404)
    
    def handle_mcp_request(self):
        """Handle MCP tool call requests"""
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            request_data = json.loads(post_data.decode('utf-8'))
            
            tool_name = request_data.get('tool')
            arguments = request_data.get('arguments', {})
            
            if not tool_name:
                self.send_json_response({'error': 'Missing tool name'}, status=400)
                return
            
            # Execute the MCP tool call
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            try:
                result = loop.run_until_complete(handle_tool_call(tool_name, arguments))
                
                # Extract text content from MCP result
                if result and len(result) > 0:
                    response_text = result[0].text if hasattr(result[0], 'text') else str(result[0])
                else:
                    response_text = f"Command {tool_name} executed successfully"
                
                self.send_json_response({
                    'success': True,
                    'data': response_text,
                    'tool': tool_name
                })
            finally:
                loop.close()
                
        except json.JSONDecodeError:
            self.send_json_response({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            self.send_json_response({'error': str(e)}, status=500)
    
    def send_json_response(self, data, status=200):
        """Send a JSON response"""
        self.send_response(status)
        self.send_header('Content-type', 'application/json')
        self.send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))
    
    def log_message(self, format, *args):
        """Custom log message format"""
        print(f"[{self.date_time_string()}] {format % args}")

def run_server(port=8000):
    """Run the HTTP server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, MCPHTTPHandler)
    
    print(f"Starting MCP HTTP server on port {port}")
    print(f"Open http://localhost:{port} in your browser")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("Invalid port number, using default 8000")
    
    run_server(port)
