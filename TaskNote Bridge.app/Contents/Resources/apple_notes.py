"""
Apple Notes integration for TaskNote Bridge
Provides functionality to create, search, and retrieve notes from Apple Notes app
"""

import subprocess
import json
from typing import Optional, List, Dict, Any
from datetime import datetime


class AppleScriptResult:
    """Result of AppleScript execution"""
    def __init__(self, success: bool, output: str, error: Optional[str] = None):
        self.success = success
        self.output = output
        self.error = error


class Note:
    """Represents a note in Apple Notes"""
    def __init__(self, id: str, title: str, content: str, tags: List[str] = None,
                 created: datetime = None, modified: datetime = None):
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags or []
        self.created = created or datetime.now()
        self.modified = modified or datetime.now()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "title": self.title,
            "content": self.content,
            "tags": self.tags,
            "created": self.created.isoformat(),
            "modified": self.modified.isoformat()
        }


def run_applescript(script: str) -> AppleScriptResult:
    """
    Execute an AppleScript command and return the result
    
    Args:
        script: The AppleScript command to execute
        
    Returns:
        AppleScriptResult containing success status and output/error
    """
    try:
        # Use subprocess.Popen with communicate() for better AppleScript handling
        # as suggested in the leancrew.com article about Python and AppleScript
        process = subprocess.Popen(
            ['osascript'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Send the script to osascript via stdin
        stdout, stderr = process.communicate(input=script, timeout=10)
        
        if process.returncode == 0:
            return AppleScriptResult(
                success=True,
                output=stdout.strip()
            )
        else:
            return AppleScriptResult(
                success=False,
                output='',
                error=stderr.strip()
            )
            
    except subprocess.TimeoutExpired:
        process.kill()
        return AppleScriptResult(
            success=False,
            output='',
            error='AppleScript execution timed out'
        )
    except Exception as e:
        return AppleScriptResult(
            success=False,
            output='',
            error=f'Error executing AppleScript: {str(e)}'
        )


def format_content(content: str) -> str:
    """
    Format note content for AppleScript compatibility
    
    Args:
        content: The raw note content
        
    Returns:
        Formatted content with proper HTML line breaks
    """
    if not content:
        return ''
    
    # Split content into lines and wrap each in div tags
    lines = content.split('\n')
    formatted_lines = []
    
    for line in lines:
        # Escape quotes for AppleScript
        escaped_line = line.replace('"', '\\"')
        # Wrap each line in a div tag, use &nbsp; for empty lines
        if escaped_line.strip() == '':
            formatted_lines.append('<div>&nbsp;</div>')
        else:
            formatted_lines.append(f'<div>{escaped_line}</div>')
    
    result = ''.join(formatted_lines)
    return result


class AppleNotesManager:
    """Manager class for Apple Notes operations"""
    
    def __init__(self, account: str = "iCloud"):
        self.account = account
    
    def create_note(self, title: str, content: str, tags: List[str] = None) -> Optional[Note]:
        """
        Create a new note in Apple Notes
        
        Args:
            title: The note title
            content: The note content
            tags: Optional array of tags
            
        Returns:
            The created note object or None if creation fails
        """
        # Escape quotes for AppleScript and format content with HTML line breaks
        escaped_title = title.replace('"', '\\"')
        formatted_content = format_content(content)
        
        script = f'tell application "Notes" to tell account "{self.account}" to make new note with properties {{name:"{escaped_title}", body:"{formatted_content}"}}'
        
        result = run_applescript(script)
        if not result.success:
            print(f'Failed to create note: {result.error}')
            return None
        
        return Note(
            id=str(int(datetime.now().timestamp() * 1000)),
            title=title,
            content=content,
            tags=tags or [],
            created=datetime.now(),
            modified=datetime.now()
        )
    
    def search_notes(self, query: str) -> List[Note]:
        """
        Search for notes by title - supports multiple search terms
        
        Args:
            query: The search query (multiple words will be searched individually)
            
        Returns:
            Array of matching notes
        """
        # Split query into individual terms for more flexible searching
        search_terms = [term.strip() for term in query.split() if term.strip()]
        
        if not search_terms:
            return []
        
        # Build AppleScript condition for multiple terms
        sanitized_terms = [term.replace('"', '\\"') for term in search_terms]
        
        notes = []
        
        # First try: AND search (all terms must be present)
        if len(sanitized_terms) > 1:
            conditions = [f'name contains "{term}"' for term in sanitized_terms]
            where_clause = ' and '.join(conditions)
            
            script = f'tell application "Notes" to tell account "{self.account}" to get name of notes where {where_clause}'
            
            result = run_applescript(script)
            if result.success and result.output:
                note_titles = [title.strip() for title in result.output.split(',') if title.strip()]
                for title in note_titles:
                    notes.append(Note(
                        id=str(int(datetime.now().timestamp() * 1000)),
                        title=title,
                        content='',
                        tags=[],
                        created=datetime.now(),
                        modified=datetime.now()
                    ))
        
        # If AND search found results or we only have one term, return those results
        if notes or len(sanitized_terms) == 1:
            if len(sanitized_terms) == 1:
                # Single term search
                script = f'tell application "Notes" to tell account "{self.account}" to get name of notes where name contains "{sanitized_terms[0]}"'
                result = run_applescript(script)
                if result.success and result.output:
                    note_titles = [title.strip() for title in result.output.split(',') if title.strip()]
                    for title in note_titles:
                        notes.append(Note(
                            id=str(int(datetime.now().timestamp() * 1000)),
                            title=title,
                            content='',
                            tags=[],
                            created=datetime.now(),
                            modified=datetime.now()
                        ))
            return notes
        
        # Fallback: OR search (any term can be present) if AND search found nothing
        conditions = [f'name contains "{term}"' for term in sanitized_terms]
        where_clause = ' or '.join(conditions)
        
        script = f'tell application "Notes" to tell account "{self.account}" to get name of notes where {where_clause}'
        
        result = run_applescript(script)
        if not result.success:
            print(f'Failed to search notes: {result.error}')
            return []
        
        # Parse the output - AppleScript returns comma-separated values
        if not result.output:
            return []
        
        note_titles = [title.strip() for title in result.output.split(',') if title.strip()]
        
        for title in note_titles:
            notes.append(Note(
                id=str(int(datetime.now().timestamp() * 1000)),
                title=title,
                content='',  # Content not retrieved in search
                tags=[],
                created=datetime.now(),
                modified=datetime.now()
            ))
        
        return notes
    
    def get_note_content(self, title: str) -> str:
        """
        Retrieve the content of a specific note
        
        Args:
            title: The exact title of the note
            
        Returns:
            The note content or empty string if not found
        """
        sanitized_title = title.replace('"', '\\"')
        script = f'tell application "Notes" to tell account "{self.account}" to get body of note "{sanitized_title}"'
        
        result = run_applescript(script)
        if not result.success:
            print(f'Failed to get note content: {result.error}')
            return ''
        
        return result.output
    
    def list_all_notes(self) -> List[Note]:
        """
        List all notes in the account
        
        Returns:
            Array of all notes
        """
        script = f'tell application "Notes" to tell account "{self.account}" to get name of notes'
        
        result = run_applescript(script)
        if not result.success:
            print(f'Failed to list notes: {result.error}')
            return []
        
        if not result.output:
            return []
        
        note_titles = [title.strip() for title in result.output.split(',') if title.strip()]
        
        notes = []
        for title in note_titles:
            notes.append(Note(
                id=str(int(datetime.now().timestamp() * 1000)),
                title=title,
                content='',
                tags=[],
                created=datetime.now(),
                modified=datetime.now()
            ))
        
        return notes
    
    def open_note(self, title: str) -> bool:
        """
        Open a specific note in Apple Notes app
        
        Args:
            title: The exact title of the note to open
            
        Returns:
            True if note was opened successfully, False otherwise
        """
        sanitized_title = title.replace('"', '\\"')
        script = f'''
        tell application "Notes"
            activate
            tell account "{self.account}"
                try
                    show note "{sanitized_title}"
                    return true
                on error
                    return false
                end try
            end tell
        end tell
        '''
        
        result = run_applescript(script)
        return result.success and result.output.strip().lower() == 'true'

    def delete_note(self, title: str) -> bool:
        """
        Delete a note by title
        
        Args:
            title: The exact title of the note to delete
            
        Returns:
            True if deletion was successful, False otherwise
        """
        sanitized_title = title.replace('"', '\\"')
        script = f'tell application "Notes" to tell account "{self.account}" to delete note "{sanitized_title}"'
        
        result = run_applescript(script)
        return result.success
