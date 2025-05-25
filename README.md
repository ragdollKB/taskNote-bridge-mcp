# TaskNote Bridge - Things 3 + Apple Notes MCP Tool

TaskNote Bridge is a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) server that lets you use Claude Desktop and GitHub Copilot to interact with your task management data in [Things app](https://culturedcode.com/things) and [Apple Notes](https://support.apple.com/guide/notes/welcome/mac). You can ask AI assistants to create tasks, analyze projects, help manage priorities, take notes, and more.

This server leverages the [Things.py](https://github.com/thingsapi/things.py) library, the [Things URL Scheme](https://culturedcode.com/things/help/url-scheme/), and AppleScript for Apple Notes integration. 

<a href="https://glama.ai/mcp/servers/t9cgixg2ah"><img width="380" height="200" src="https://glama.ai/mcp/servers/t9cgixg2ah/badge" alt="Things Server MCP server" /></a>

## Features

### Things 3 Integration
- Access to all major Things lists (Inbox, Today, Upcoming, etc.)
- Project and area management
- Tag operations
- Advanced search capabilities
- Recent items tracking
- Detailed item information including checklists
- Support for nested data (projects within areas, todos within projects)
- Open specific tasks directly in Things 3 app

### Apple Notes Integration
- Create new notes with titles, content, and tags
- Search notes by title
- Retrieve note content
- List all notes
- Open notes directly in Apple Notes app
- Delete notes
- Full AppleScript integration for seamless macOS experience

## Installation

### For Claude Desktop

1. Prerequisites 
* Python 3.12+
* Claude Desktop
* Things 3 ("Enable Things URLs" must be turned on in Settings -> General)
* Apple Notes (for note management features)
* macOS (required for AppleScript integration)

2. Install uv if you haven't already:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```
Restart your terminal afterwards.

3. Clone this repository:
```bash
git clone https://github.com/ragdollKB/things-mcp
cd things-mcp
```

4. Install the required Python packages:
```bash
uv venv
uv pip install -e .
```

5. Run the configuration setup script:
```bash
uv run python setup_config.py
```
This script will generate the correct configuration for your system and help you set it up automatically.

Alternatively, you can manually edit the Claude Desktop configuration file:
```bash
code ~/Library/Application\ Support/Claude/claude_desktop_config.json
```
Add the Things server to the mcpServers key (replace `/PATH/TO/YOUR/things-mcp` with your actual installation path):
```json
{
    "mcpServers": {
        "things": {
            "command": "uv",
            "args": [
                "--directory",
                "/PATH/TO/YOUR/things-mcp",
                "run",
                "things_server.py"
            ]
        }
    }
}
```
Restart the Claude Desktop app.

### For VSCode (with MCP extension)

1. Prerequisites
* Python 3.12+
* VSCode or VSCode Insiders
* Things 3 ("Enable Things URLs" must be turned on in Settings -> General)
* Apple Notes (for note management features)
* macOS (required for AppleScript integration)
* MCP extension for VSCode

2. Follow the installation steps from the Claude Desktop section above (steps 1-4).

3. Install the MCP extension for VSCode:
   - Open VSCode
   - Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
   - Search for "MCP" and install the official MCP extension

4. Run the configuration setup script:
```bash
uv run python setup_config.py
```
Choose option 2 for VSCode configuration.

Alternatively, you can manually configure VSCode settings:
   - Open Settings (Ctrl+, / Cmd+,)
   - Click "Open Settings (JSON)" in the top right
   - Add this configuration (replace `/PATH/TO/YOUR/things-mcp` with your actual installation path):

```json
{
    "mcp": {
        "inputs": [],
        "servers": {
            "things": {
                "command": "uv",
                "args": [
                    "--directory",
                    "/PATH/TO/YOUR/things-mcp",
                    "run",
                    "things_server.py"
                ]
            }
        }
    }
}
```

5. Restart VSCode to load the MCP server.

### Usage in VSCode

With the MCP extension installed and configured:
1. Open the Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Type "MCP" to see available MCP commands
3. Use "MCP: Call Tool" to interact with Things tools
4. Or use any AI assistant that supports MCP to access your Things data

### For Web Browser Interface

1. Prerequisites
* Python 3.12+
* Things 3 ("Enable Things URLs" must be turned on in Settings -> General)

2. Follow steps 2-4 from the Claude Desktop installation above to install dependencies.

3. Start the web server:
```bash
cd things-mcp
uv run python web_server.py
```

4. Open your browser and go to: `http://localhost:8000`

5. Use the web interface to:
   - Load your tasks directly from Things via MCP
   - Create new tasks through the MCP server
   - Generate and execute Things URL schemes
   - Chat with an AI assistant that can access your Things data

### For Other MCP Tools

This server follows the standard MCP protocol and can work with any MCP-compatible tool. Configure the tool to execute `things_server.py` as an MCP server using the command line shown above.

### Sample Usage with Claude Desktop
* "What's on my todo list today?"
* "Create a todo to pack for my beach vacation next week, include a packling checklist."
* "Evaluate my current todos using the Eisenhower matrix."
* "Help me conduct a GTD-style weekly review using Things."

#### Tips
* Create a project in Claude with custom instructions that explains how you use Things and organize areas, projects, tags, etc. Tell Claude what information you want included when it creates a new task (eg asking it to include relevant details in the task description might be helpful).
* Try adding another MCP server that gives Claude access to your calendar. This will let you ask Claude to block time on your calendar for specific tasks, create todos from upcoming calendar events (eg prep for a meeting), etc.


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
- `open-todo` - Search for a todo by title and open it in Things app

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

### open-todo
- `title` - Title or partial title of the todo to search for and open

### notes-open
- `title` - Exact title of the note to open in Apple Notes


## Troubleshooting

The server includes error handling for:
- Invalid UUIDs
- Missing required parameters
- Things database access errors
- Data formatting errors

All errors are logged and returned with descriptive messages. To review the MCP logs from Claude Desktop, run this in the Terminal:
```bash
# Follow logs in real-time
tail -n 20 -f ~/Library/Logs/Claude/mcp*.log
```
