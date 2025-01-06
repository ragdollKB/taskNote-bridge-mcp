import mcp.types as types

def get_tools_list() -> list[types.Tool]:
    """Return the list of available tools."""
    return [
        # Basic operations
        types.Tool(
            name="get-todos",
            description="Get todos from Things, optionally filtered by project",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_uuid": {
                        "type": "string",
                        "description": "Optional UUID of a specific project to get todos from",
                    },
                    "include_items": {
                        "type": "boolean",
                        "description": "Include checklist items",
                        "default": True
                    }
                },
                "required": [],
            },
        ),
        types.Tool(
            name="get-projects",
            description="Get all projects from Things",
            inputSchema={
                "type": "object",
                "properties": {
                    "include_items": {
                        "type": "boolean",
                        "description": "Include tasks within projects",
                        "default": False
                    }
                },
                "required": [],
            },
        ),
        types.Tool(
            name="get-areas",
            description="Get all areas from Things",
            inputSchema={
                "type": "object",
                "properties": {
                    "include_items": {
                        "type": "boolean",
                        "description": "Include projects and tasks within areas",
                        "default": False
                    }
                },
                "required": [],
            },
        ),
        
        # List views
        types.Tool(
            name="get-inbox",
            description="Get todos from Inbox",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        types.Tool(
            name="get-today",
            description="Get todos due today",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        types.Tool(
            name="get-upcoming",
            description="Get upcoming todos",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        types.Tool(
            name="get-anytime",
            description="Get todos from Anytime list",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        types.Tool(
            name="get-someday",
            description="Get todos from Someday list",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        types.Tool(
            name="get-logbook",
            description="Get completed todos from Logbook",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        types.Tool(
            name="get-trash",
            description="Get trashed todos",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": [],
            },
        ),
        
        # Tag operations
        types.Tool(
            name="get-tags",
            description="Get all tags",
            inputSchema={
                "type": "object",
                "properties": {
                    "include_items": {
                        "type": "boolean",
                        "description": "Include items tagged with each tag",
                        "default": False
                    }
                },
                "required": [],
            },
        ),
        types.Tool(
            name="get-tagged-items",
            description="Get items with a specific tag",
            inputSchema={
                "type": "object",
                "properties": {
                    "tag": {
                        "type": "string",
                        "description": "Tag title to filter by"
                    }
                },
                "required": ["tag"],
            },
        ),
        
        # Search operations
        types.Tool(
            name="search-todos",
            description="Search todos by title or notes",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search term to look for in todo titles and notes",
                    },
                },
                "required": ["query"],
            },
        ),
        types.Tool(
            name="search-advanced",
            description="Advanced todo search with multiple filters",
            inputSchema={
                "type": "object",
                "properties": {
                    "status": {
                        "type": "string",
                        "enum": ["incomplete", "completed", "canceled"],
                        "description": "Filter by todo status"
                    },
                    "start_date": {
                        "type": "string",
                        "description": "Filter by start date (YYYY-MM-DD)"
                    },
                    "deadline": {
                        "type": "string",
                        "description": "Filter by deadline (YYYY-MM-DD)"
                    },
                    "tag": {
                        "type": "string",
                        "description": "Filter by tag"
                    },
                    "area": {
                        "type": "string",
                        "description": "Filter by area UUID"
                    },
                    "type": {
                        "type": "string",
                        "enum": ["to-do", "project", "heading"],
                        "description": "Filter by item type"
                    }
                },
                "required": [],
            },
        ),
        
        # Recent items
        types.Tool(
            name="get-recent",
            description="Get recently created items",
            inputSchema={
                "type": "object",
                "properties": {
                    "period": {
                        "type": "string",
                        "description": "Time period (e.g., '3d', '1w', '2m', '1y')",
                        "pattern": "^\\d+[dwmy]$"
                    }
                },
                "required": ["period"],
            },
        ),
    ]