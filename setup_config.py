#!/usr/bin/env python3
"""
Setup script to generate MCP configuration for TaskNote Bridge.
This script helps users configure the server for Claude Desktop or VSCode.
"""

import os
import json
import platform
from pathlib import Path


def get_current_directory():
    """Get the absolute path to the current directory."""
    return os.path.abspath(os.getcwd())


def get_claude_config_path():
    """Get the path to Claude Desktop configuration file."""
    if platform.system() == "Darwin":  # macOS
        return os.path.expanduser("~/Library/Application Support/Claude/claude_desktop_config.json")
    elif platform.system() == "Windows":
        return os.path.expanduser("~/AppData/Roaming/Claude/claude_desktop_config.json")
    else:  # Linux
        return os.path.expanduser("~/.config/claude/claude_desktop_config.json")


def generate_claude_config():
    """Generate Claude Desktop configuration."""
    current_dir = get_current_directory()
    
    config = {
        "mcpServers": {
            "things": {
                "command": "uv",
                "args": [
                    "--directory",
                    current_dir,
                    "run",
                    "things_server.py"
                ]
            }
        }
    }
    
    return config


def generate_vscode_config():
    """Generate VSCode MCP configuration."""
    current_dir = get_current_directory()
    
    config = {
        "mcp": {
            "inputs": [],
            "servers": {
                "things": {
                    "command": "uv",
                    "args": [
                        "--directory",
                        current_dir,
                        "run",
                        "things_server.py"
                    ]
                }
            }
        }
    }
    
    return config


def main():
    print("🚀 TaskNote Bridge - Configuration Setup")
    print("=" * 50)
    
    # Check if we're on macOS
    if platform.system() != "Darwin":
        print("⚠️  Warning: This tool is designed for macOS and requires Things 3 and Apple Notes.")
        print("   It may not work correctly on other platforms.")
        print()
    
    # Check if required files exist
    current_dir = get_current_directory()
    server_file = os.path.join(current_dir, "things_server.py")
    
    if not os.path.exists(server_file):
        print("❌ Error: things_server.py not found in current directory.")
        print(f"   Current directory: {current_dir}")
        print("   Please run this script from the TaskNote Bridge directory.")
        return
    
    print(f"✅ Found server at: {current_dir}")
    print()
    
    # Ask user which configuration they want
    print("Which application do you want to configure?")
    print("1. Claude Desktop")
    print("2. VSCode")
    print("3. Both")
    print("4. Just show me the configurations")
    
    choice = input("\nEnter your choice (1-4): ").strip()
    
    if choice in ["1", "3", "4"]:
        print("\n" + "="*50)
        print("CLAUDE DESKTOP CONFIGURATION")
        print("="*50)
        
        claude_config = generate_claude_config()
        claude_config_path = get_claude_config_path()
        
        print(f"Add this to your Claude Desktop config file:")
        print(f"Location: {claude_config_path}")
        print()
        print(json.dumps(claude_config, indent=2))
        
        if choice == "1":
            # Try to update Claude config automatically
            try:
                claude_dir = os.path.dirname(claude_config_path)
                os.makedirs(claude_dir, exist_ok=True)
                
                existing_config = {}
                if os.path.exists(claude_config_path):
                    with open(claude_config_path, 'r') as f:
                        existing_config = json.load(f)
                
                # Merge configurations
                if "mcpServers" not in existing_config:
                    existing_config["mcpServers"] = {}
                
                existing_config["mcpServers"]["things"] = claude_config["mcpServers"]["things"]
                
                with open(claude_config_path, 'w') as f:
                    json.dump(existing_config, f, indent=2)
                
                print(f"\n✅ Updated Claude Desktop configuration at: {claude_config_path}")
                print("   Restart Claude Desktop to apply changes.")
                
            except Exception as e:
                print(f"\n⚠️  Could not automatically update config: {e}")
                print("   Please manually add the configuration above.")
    
    if choice in ["2", "3", "4"]:
        print("\n" + "="*50)
        print("VSCODE CONFIGURATION")
        print("="*50)
        
        vscode_config = generate_vscode_config()
        
        print("Add this to your VSCode settings.json:")
        print("(Open Settings → Click 'Open Settings (JSON)' in top right)")
        print()
        print(json.dumps(vscode_config, indent=2))
        print()
        print("After adding the configuration:")
        print("1. Install the MCP extension for VSCode")
        print("2. Restart VSCode")
    
    print("\n" + "="*50)
    print("PREREQUISITES")
    print("="*50)
    print("Make sure you have:")
    print("✓ Python 3.12+")
    print("✓ uv package manager installed")
    print("✓ Things 3 with 'Enable Things URLs' turned on")
    print("✓ Apple Notes app")
    print("✓ macOS (required for AppleScript integration)")
    
    print("\nTo install dependencies, run:")
    print("  uv venv")
    print("  uv pip install -e .")
    
    print("\nTo test the server, run:")
    print("  uv run python test_server.py")
    
    print("\n🎉 Setup complete! Enjoy using TaskNote Bridge!")


if __name__ == "__main__":
    main()
