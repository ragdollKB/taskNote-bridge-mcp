#!/usr/bin/env python3
"""
Test script for Apple Notes integration
"""

import sys
import os

# Add the current directory to the path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from apple_notes import AppleNotesManager


def test_apple_notes_integration():
    """Test the Apple Notes integration"""
    print("🧪 Testing Apple Notes Integration...")
    
    # Initialize the notes manager
    notes_manager = AppleNotesManager()
    
    # Test 1: Create a note
    print("\n📝 Test 1: Creating a test note...")
    test_note = notes_manager.create_note(
        title="MCP Integration Test",
        content="This is a test note created via the Things MCP server with Apple Notes integration.\n\nFeatures tested:\n- Create notes via MCP\n- Python AppleScript integration\n- Cross-app functionality\n\nCreated on: May 24, 2025",
        tags=["testing", "mcp", "integration"]
    )
    
    if test_note:
        print(f"✅ Successfully created note: '{test_note.title}'")
    else:
        print("❌ Failed to create note")
        return False
    
    # Test 2: Search for the note
    print("\n🔍 Test 2: Searching for notes...")
    search_results = notes_manager.search_notes("MCP Integration")
    
    if search_results:
        print(f"✅ Found {len(search_results)} notes:")
        for note in search_results:
            print(f"   • {note.title}")
    else:
        print("❌ No notes found in search")
    
    # Test 3: Get note content
    print("\n📖 Test 3: Getting note content...")
    content = notes_manager.get_note_content("MCP Integration Test")
    
    if content:
        print("✅ Successfully retrieved note content:")
        print(f"   Content length: {len(content)} characters")
        print(f"   First 100 chars: {content[:100]}...")
    else:
        print("❌ Failed to retrieve note content")
    
    # Test 4: List all notes
    print("\n📋 Test 4: Listing all notes...")
    all_notes = notes_manager.list_all_notes()
    
    if all_notes:
        print(f"✅ Found {len(all_notes)} total notes")
        # Show first 5 notes
        for i, note in enumerate(all_notes[:5]):
            print(f"   {i+1}. {note.title}")
        if len(all_notes) > 5:
            print(f"   ... and {len(all_notes) - 5} more")
    else:
        print("❌ No notes found")
    
    print("\n🎉 Apple Notes integration test completed!")
    return True


if __name__ == "__main__":
    try:
        test_apple_notes_integration()
    except Exception as e:
        print(f"❌ Test failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
