import logging
from typing import List
import things
import mcp.types as types
from formatters import format_todo, format_project, format_area, format_tag
import url_scheme
from apple_notes import AppleNotesManager

logger = logging.getLogger(__name__)

# Initialize Apple Notes manager
notes_manager = AppleNotesManager()


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
                "get-trash": things.trash,
            }

            if name == "get-logbook":
                # Handle logbook with limits
                period = arguments.get("period", "7d") if arguments else "7d"
                limit = arguments.get("limit", 50) if arguments else 50
                todos = things.last(period, status='completed')
                if todos and len(todos) > limit:
                    todos = todos[:limit]
            else:
                todos = list_funcs[name]()

            if not todos:
                return [types.TextContent(type="text", text="No items found")]

            formatted_todos = [format_todo(todo) for todo in todos]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_todos))]

        # Basic todo operations
        elif name == "get-todos":
            project_uuid = arguments.get("project_uuid") if arguments else None
            include_items = arguments.get(
                "include_items", True) if arguments else True

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
            include_items = arguments.get(
                "include_items", False) if arguments else False
            projects = things.projects()

            if not projects:
                return [types.TextContent(type="text", text="No projects found")]

            formatted_projects = [format_project(
                project, include_items) for project in projects]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_projects))]

        # Area operations
        elif name == "get-areas":
            include_items = arguments.get(
                "include_items", False) if arguments else False
            areas = things.areas()

            if not areas:
                return [types.TextContent(type="text", text="No areas found")]

            formatted_areas = [format_area(
                area, include_items) for area in areas]
            return [types.TextContent(type="text", text="\n\n---\n\n".join(formatted_areas))]

        # Tag operations
        elif name == "get-tags":
            include_items = arguments.get(
                "include_items", False) if arguments else False
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

        # Things URL scheme operations
        elif name == "add-todo":
            if not arguments or "title" not in arguments:
                raise ValueError("Missing title parameter")

            url = url_scheme.add_todo(
                title=arguments["title"],
                notes=arguments.get("notes"),
                when=arguments.get("when"),
                deadline=arguments.get("deadline"),
                tags=arguments.get("tags"),
                checklist_items=arguments.get("checklist_items"),
                list_id=arguments.get("list_id"),
                list_title=arguments.get("list_title"),
                heading=arguments.get("heading")
            )
            url_scheme.execute_url(url)
            return [types.TextContent(type="text", text=f"Created new todo: {arguments['title']}")]

        elif name == "search-items":
            if not arguments or "query" not in arguments:
                raise ValueError("Missing query parameter")

            url = url_scheme.search(arguments["query"])
            url_scheme.execute_url(url)
            return [types.TextContent(type="text", text=f"Searching for '{arguments['query']}'")]

        elif name == "add-project":
            if not arguments or "title" not in arguments:
                raise ValueError("Missing title parameter")

            url = url_scheme.add_project(
                title=arguments["title"],
                notes=arguments.get("notes"),
                when=arguments.get("when"),
                deadline=arguments.get("deadline"),
                tags=arguments.get("tags"),
                area_id=arguments.get("area_id"),
                area_title=arguments.get("area_title"),
                todos=arguments.get("todos")
            )
            url_scheme.execute_url(url)
            return [types.TextContent(type="text", text="Created new project")]

        elif name == "update-todo":
            if not arguments or "id" not in arguments:
                raise ValueError("Missing id parameter")

            url = url_scheme.update_todo(
                id=arguments["id"],
                title=arguments.get("title"),
                notes=arguments.get("notes"),
                when=arguments.get("when"),
                deadline=arguments.get("deadline"),
                tags=arguments.get("tags"),
                completed=arguments.get("completed"),
                canceled=arguments.get("canceled")
            )
            url_scheme.execute_url(url)
            return [types.TextContent(type="text", text="Updated todo")]

        elif name == "update-project":
            if not arguments or "id" not in arguments:
                raise ValueError("Missing id parameter")

            url = url_scheme.update_project(
                id=arguments["id"],
                title=arguments.get("title"),
                notes=arguments.get("notes"),
                when=arguments.get("when"),
                deadline=arguments.get("deadline"),
                tags=arguments.get("tags"),
                completed=arguments.get("completed"),
                canceled=arguments.get("canceled")
            )
            url_scheme.execute_url(url)
            return [types.TextContent(type="text", text="Updated project")]

        elif name == "show-item":
            if not arguments or "id" not in arguments:
                raise ValueError("Missing id parameter")

            url = url_scheme.show(
                id=arguments["id"],
                query=arguments.get("query"),
                filter_tags=arguments.get("filter_tags")
            )
            url_scheme.execute_url(url)
            return [types.TextContent(type="text", text=f"Opened '{arguments['id']}' in Things app")]

        elif name == "open-todo":
            if not arguments or "title" not in arguments:
                raise ValueError("Missing title parameter")

            title = arguments["title"]
            
            # Search for todos matching the title
            todos = things.search(title)
            
            if not todos:
                return [types.TextContent(type="text", text=f"No todos found matching '{title}'")]
            
            # Find the best match (exact title match first, then partial)
            exact_match = None
            partial_matches = []
            
            for todo in todos:
                if todo['title'].lower() == title.lower():
                    exact_match = todo
                    break
                elif title.lower() in todo['title'].lower():
                    partial_matches.append(todo)
            
            # Use exact match if found, otherwise use first partial match
            todo_to_open = exact_match if exact_match else (partial_matches[0] if partial_matches else todos[0])
            
            # Open the todo using its UUID
            url = url_scheme.show(id=todo_to_open['uuid'])
            url_scheme.execute_url(url)
            
            return [types.TextContent(type="text", text=f"✅ Opened todo: \"{todo_to_open['title']}\" in Things app")]

        # Apple Notes handlers
        elif name == "notes-create":
            if not arguments:
                raise ValueError("Missing arguments")
            
            title = arguments.get("title")
            content = arguments.get("content")
            tags = arguments.get("tags", [])
            
            if not title:
                raise ValueError("Title is required")
            if not content:
                raise ValueError("Content is required")
            
            note = notes_manager.create_note(title, content, tags)
            
            if note:
                return [types.TextContent(type="text", text=f"✅ Note created successfully: \"{note.title}\"")]
            else:
                return [types.TextContent(type="text", text="Failed to create note. Please check your Apple Notes configuration.")]

        elif name == "notes-search":
            if not arguments or "query" not in arguments:
                raise ValueError("Missing query parameter")
            
            query = arguments["query"]
            notes = notes_manager.search_notes(query)
            
            if notes:
                note_list = [f"• {note.title}" for note in notes]
                message = f"Found {len(notes)} notes:\n" + "\n".join(note_list)
            else:
                message = "No notes found matching your query"
            
            return [types.TextContent(type="text", text=message)]

        elif name == "notes-get-content":
            if not arguments or "title" not in arguments:
                raise ValueError("Missing title parameter")
            
            title = arguments["title"]
            content = notes_manager.get_note_content(title)
            
            if content:
                return [types.TextContent(type="text", text=f"**{title}**\n\n{content}")]
            else:
                return [types.TextContent(type="text", text="Note not found")]

        elif name == "notes-list":
            notes = notes_manager.list_all_notes()
            
            if notes:
                note_list = [f"• {note.title}" for note in notes]
                message = f"Found {len(notes)} notes:\n" + "\n".join(note_list)
            else:
                message = "No notes found"
            
            return [types.TextContent(type="text", text=message)]

        elif name == "notes-open":
            if not arguments or "title" not in arguments:
                raise ValueError("Missing title parameter")
            
            title = arguments["title"]
            success = notes_manager.open_note(title)
            
            if success:
                return [types.TextContent(type="text", text=f"✅ Note opened successfully: \"{title}\"")]
            else:
                return [types.TextContent(type="text", text=f"Failed to open note: \"{title}\". Note may not exist.")]

        elif name == "notes-delete":
            if not arguments or "title" not in arguments:
                raise ValueError("Missing title parameter")
            
            title = arguments["title"]
            success = notes_manager.delete_note(title)
            
            if success:
                return [types.TextContent(type="text", text=f"✅ Note deleted successfully: \"{title}\"")]
            else:
                return [types.TextContent(type="text", text=f"Failed to delete note: \"{title}\". Note may not exist.")]

        else:
            raise ValueError(f"Unknown tool: {name}")

    except Exception as e:
        logger.error(f"Error handling tool {name}: {str(e)}", exc_info=True)
        return [types.TextContent(type="text", text=f"Error: {str(e)}")]
