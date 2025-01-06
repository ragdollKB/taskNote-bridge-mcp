import logging
from typing import List
import things
import mcp.types as types
from formatters import format_todo, format_project, format_area, format_tag

logger = logging.getLogger(__name__)

async def handle_tool_call(
    name: str, 
    arguments: dict | None
) -> list[types.TextContent | types.ImageContent | types.EmbeddedResource]:
    """Handle tool execution requests."""
    try:
        # List view handlers
        if name in ["get-inbox", "get-today", "get-upcoming", "get-anytime", 
                   "get-someday", "get-logbook", "get-trash"]:
            list_funcs = {
                "get-inbox": things.inbox,
                "get-today": things.today,
                "get-upcoming": things.upcoming,
                "get-anytime": things.anytime,
                "get-someday": things.someday,
                "get-logbook": things.logbook,
                "get-trash": things.trash
            }
            
            todos = list_funcs[name]()
            if not todos:
                return [types.TextContent(type="text", text="No items found")]
                
            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        # Basic todo operations
        elif name == "get-todos":
            project_uuid = arguments.get("project_uuid") if arguments else None
            include_items = arguments.get("include_items", True) if arguments else True
            
            if project_uuid:
                project = things.get(project_uuid)
                if not project or project.get('type') != 'project':
                    return [types.TextContent(type="text", 
                        text=f"Error: Invalid project UUID '{project_uuid}'")]
                        
            todos = things.todos(project=project_uuid, start=None)
            if not todos:
                return [types.TextContent(type="text", text="No todos found")]
                
            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        # Project operations
        elif name == "get-projects":
            include_items = arguments.get("include_items", False) if arguments else False
            projects = things.projects()
            
            if not projects:
                return [types.TextContent(type="text", text="No projects found")]
                
            formatted_projects = [format_project(project, include_items) for project in projects]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_projects))]

        # Area operations
        elif name == "get-areas":
            include_items = arguments.get("include_items", False) if arguments else False
            areas = things.areas()
            
            if not areas:
                return [types.TextContent(type="text", text="No areas found")]
                
            formatted_areas = [format_area(area, include_items) for area in areas]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_areas))]

        # Tag operations
        elif name == "get-tags":
            include_items = arguments.get("include_items", False) if arguments else False
            tags = things.tags()
            
            if not tags:
                return [types.TextContent(type="text", text="No tags found")]
                
            formatted_tags = [format_tag(tag, include_items) for tag in tags]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_tags))]

        elif name == "get-tagged-items":
            if not arguments or "tag" not in arguments:
                raise ValueError("Missing tag parameter")
                
            tag = arguments["tag"]
            todos = things.todos(tag=tag)
            
            if not todos:
                return [types.TextContent(type="text", 
                    text=f"No items found with tag '{tag}'")]
                
            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        # Search operations
        elif name == "search-todos":
            if not arguments or "query" not in arguments:
                raise ValueError("Missing query parameter")
                
            query = arguments["query"]
            todos = things.search(query)
            
            if not todos:
                return [types.TextContent(type="text", 
                    text=f"No todos found matching '{query}'")]
                
            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        elif name == "search-advanced":
            if not arguments:
                raise ValueError("Missing search parameters")
                
            # Convert the arguments to things.todos() parameters
            search_params = {}
            
            # Handle status
            if "status" in arguments:
                search_params["status"] = arguments["status"]
                
            # Handle dates
            if "start_date" in arguments:
                search_params["start_date"] = arguments["start_date"]
            if "deadline" in arguments:
                search_params["deadline"] = arguments["deadline"]
                
            # Handle tag
            if "tag" in arguments:
                search_params["tag"] = arguments["tag"]
                
            # Handle area
            if "area" in arguments:
                search_params["area"] = arguments["area"]
                
            # Handle type
            if "type" in arguments:
                search_params["type"] = arguments["type"]
            
            todos = things.todos(**search_params)
            
            if not todos:
                return [types.TextContent(type="text", text="No matching todos found")]
                
            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        # Recent items
        elif name == "get-recent":
            if not arguments or "period" not in arguments:
                raise ValueError("Missing period parameter")
                
            period = arguments["period"]
            todos = things.last(period)
            
            if not todos:
                return [types.TextContent(type="text", 
                    text=f"No items found in the last {period}")]
                
            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        else:
            raise ValueError(f"Unknown tool: {name}")

    except Exception as e:
        logger.error(f"Error handling tool {name}: {str(e)}", exc_info=True)
        return [types.TextContent(type="text", text=f"Error: {str(e)}")]