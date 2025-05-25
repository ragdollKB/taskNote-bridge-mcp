"""
Apple Notes tools for MCP server integration
"""

from typing import Any, Dict, List
from apple_notes import AppleNotesManager


def create_apple_notes_tools(notes_manager: AppleNotesManager = None) -> Dict[str, Any]:
    """
    Create Apple Notes tools for MCP server
    
    Args:
        notes_manager: AppleNotesManager instance, creates new one if None
        
    Returns:
        Dictionary of tool definitions
    """
    if notes_manager is None:
        notes_manager = AppleNotesManager()
    
    tools = {}
    
    # Create Note Tool
    def create_note_handler(arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Handle create note requests"""
        try:
            title = arguments.get('title', '')
            content = arguments.get('content', '')
            tags = arguments.get('tags', [])
            
            if not title:
                return {
                    'success': False,
                    'error': 'Title is required'
                }
            
            if not content:
                return {
                    'success': False,
                    'error': 'Content is required'
                }
            
            note = notes_manager.create_note(title, content, tags)
            
            if note:
                return {
                    'success': True,
                    'message': f'✅ Note created successfully: "{note.title}"',
                    'note': note.to_dict()
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create note. Please check your Apple Notes configuration.'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Error creating note: {str(e)}'
            }
    
    tools['notes_create'] = {
        'description': 'Create a new note in Apple Notes',
        'parameters': {
            'title': {'type': 'string', 'description': 'The title of the note', 'required': True},
            'content': {'type': 'string', 'description': 'The content of the note', 'required': True},
            'tags': {'type': 'array', 'description': 'Optional tags for the note', 'required': False}
        },
        'handler': create_note_handler
    }
    
    # Search Notes Tool
    def search_notes_handler(arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Handle search notes requests"""
        try:
            query = arguments.get('query', '')
            
            if not query:
                return {
                    'success': False,
                    'error': 'Search query is required'
                }
            
            notes = notes_manager.search_notes(query)
            
            if notes:
                note_list = [f"• {note.title}" for note in notes]
                message = f"Found {len(notes)} notes:\n" + "\n".join(note_list)
            else:
                message = "No notes found matching your query"
            
            return {
                'success': True,
                'message': message,
                'notes': [note.to_dict() for note in notes],
                'count': len(notes)
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Error searching notes: {str(e)}'
            }
    
    tools['notes_search'] = {
        'description': 'Search for notes by title',
        'parameters': {
            'query': {'type': 'string', 'description': 'The search query', 'required': True}
        },
        'handler': search_notes_handler
    }
    
    # Get Note Content Tool
    def get_note_content_handler(arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Handle get note content requests"""
        try:
            title = arguments.get('title', '')
            
            if not title:
                return {
                    'success': False,
                    'error': 'Note title is required'
                }
            
            content = notes_manager.get_note_content(title)
            
            if content:
                return {
                    'success': True,
                    'title': title,
                    'content': content
                }
            else:
                return {
                    'success': False,
                    'error': 'Note not found'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Error retrieving note content: {str(e)}'
            }
    
    tools['notes_get_content'] = {
        'description': 'Get the content of a specific note',
        'parameters': {
            'title': {'type': 'string', 'description': 'The exact title of the note', 'required': True}
        },
        'handler': get_note_content_handler
    }
    
    # List All Notes Tool
    def list_notes_handler(arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Handle list all notes requests"""
        try:
            notes = notes_manager.list_all_notes()
            
            if notes:
                note_list = [f"• {note.title}" for note in notes]
                message = f"Found {len(notes)} notes:\n" + "\n".join(note_list)
            else:
                message = "No notes found"
            
            return {
                'success': True,
                'message': message,
                'notes': [note.to_dict() for note in notes],
                'count': len(notes)
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Error listing notes: {str(e)}'
            }
    
    tools['notes_list'] = {
        'description': 'List all notes in Apple Notes',
        'parameters': {},
        'handler': list_notes_handler
    }
    
    # Open Note Tool
    def open_note_handler(arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Handle open note requests"""
        try:
            title = arguments.get('title', '')
            
            if not title:
                return {
                    'success': False,
                    'error': 'Note title is required'
                }
            
            success = notes_manager.open_note(title)
            
            if success:
                return {
                    'success': True,
                    'message': f'✅ Note opened successfully: "{title}"'
                }
            else:
                return {
                    'success': False,
                    'error': f'Failed to open note: "{title}". Note may not exist.'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Error opening note: {str(e)}'
            }
    
    tools['notes_open'] = {
        'description': 'Open a note in Apple Notes app',
        'parameters': {
            'title': {'type': 'string', 'description': 'The exact title of the note to open', 'required': True}
        },
        'handler': open_note_handler
    }
    
    # Delete Note Tool
    def delete_note_handler(arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Handle delete note requests"""
        try:
            title = arguments.get('title', '')
            
            if not title:
                return {
                    'success': False,
                    'error': 'Note title is required'
                }
            
            success = notes_manager.delete_note(title)
            
            if success:
                return {
                    'success': True,
                    'message': f'✅ Note deleted successfully: "{title}"'
                }
            else:
                return {
                    'success': False,
                    'error': f'Failed to delete note: "{title}". Note may not exist.'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Error deleting note: {str(e)}'
            }
    
    tools['notes_delete'] = {
        'description': 'Delete a note from Apple Notes',
        'parameters': {
            'title': {'type': 'string', 'description': 'The exact title of the note to delete', 'required': True}
        },
        'handler': delete_note_handler
    }
    
    return tools
