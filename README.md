# Things MCP Server

This MCP server provides access to Things 3 task management data through a standardized interface. It allows AI assistants and other applications to interact with Things data in a controlled and secure way.

## Features

- Access to all major Things lists (Inbox, Today, Upcoming, etc.)
- Project and area management
- Tag operations
- Advanced search capabilities
- Recent items tracking
- Detailed item information including checklists
- Support for nested data (projects within areas, todos within projects)

## File Structure

- `things_server.py` - Main server entry point
- `tools.py` - Tool definitions and schemas
- `handlers.py` - Tool execution handlers
- `formatters.py` - Output formatting functions

## Installation

1. Ensure you have Things 3 installed and running
2. Install the required Python packages:
```bash
pip install things.py mcp
```

## Usage

To start the server:
```bash
python things_server.py
```

### Available Tools

#### List Views
- `get-inbox` - Get todos from Inbox
- `get-today` - Get todos due today
- `get-upcoming` - Get upcoming todos
- `get-anytime` - Get todos from Anytime list
- `get-someday` - Get todos from Someday list
- `get-logbook` - Get completed todos
- `get-trash` - Get trashed todos

#### Basic Operations
- `get-todos` - Get todos, optionally filtered by project
- `get-projects` - Get all projects
- `get-areas` - Get all areas

#### Tag Operations
- `get-tags` - Get all tags
- `get-tagged-items` - Get items with a specific tag

#### Search Operations
- `search-todos` - Simple search by title/notes
- `search-advanced` - Advanced search with multiple filters

#### Time-based Operations
- `get-recent` - Get recently created items

## Tool Parameters

### get-todos
- `project_uuid` (optional) - Filter todos by project
- `include_items` (optional, default: true) - Include checklist items

### get-projects / get-areas / get-tags
- `include_items` (optional, default: false) - Include contained items

### search-advanced
- `status` - Filter by status (incomplete/completed/canceled)
- `start_date` - Filter by start date (YYYY-MM-DD)
- `deadline` - Filter by deadline (YYYY-MM-DD)
- `tag` - Filter by tag
- `area` - Filter by area UUID
- `type` - Filter by item type (to-do/project/heading)

### get-recent
- `period` - Time period (e.g., '3d', '1w', '2m', '1y')

## Example Tool Calls

Get todos from inbox:
```python
await session.call_tool("get-inbox", {})
```

Get todos from a specific project:
```python
await session.call_tool("get-todos", {
    "project_uuid": "YOUR-PROJECT-UUID",
    "include_items": True
})
```

Advanced search:
```python
await session.call_tool("search-advanced", {
    "status": "incomplete",
    "tag": "Priority",
    "deadline": "2024-01-31"
})
```

## Error Handling

The server includes comprehensive error handling:
- Invalid UUIDs
- Missing required parameters
- Things database access errors
- Data formatting errors

All errors are logged and returned with descriptive messages.