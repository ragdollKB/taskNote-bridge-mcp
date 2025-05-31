# Things MCP Server Usage

## Context
You are working with a Things MCP (Model Context Protocol) server that integrates with the Things 3 task management app and Apple Notes. When users request task/project creation or note management, you should use the available MCP tools.

## Available MCP Tools

### Things 3 Tools

### bb7_add-todo
Creates a new task in Things 3
- **Required**: `title` (string)
- **Optional**: `notes` (string), `deadline` (YYYY-MM-DD), `list_title` (string), `list_id` (string), `tags` (array of strings), `when` (string), `checklist_items` (array of strings), `heading` (string)

### bb7_add-project  
Creates a new project in Things 3
- **Required**: `title` (string)
- **Optional**: `notes` (string), `area_title` (string), `area_id` (string), `tags` (array of strings), `deadline` (YYYY-MM-DD), `when` (string), `todos` (array of strings)

### bb7_search-todos
Search for existing tasks
- **Required**: `query` (string)

### bb7_update-todo
Update an existing task
- **Required**: `id` (string)
- **Optional**: `title`, `notes`, `deadline`, `completed`, `tags`, `when`

### bb7_get-projects
List all projects
- **Optional**: `include_items` (boolean)

### bb7_get-today
Get today's tasks

### bb7_get-upcoming
Get upcoming tasks

### bb7_get-anytime
Get anytime tasks

### bb7_open-todo
Search for a todo by title and open it in Things 3 app
- **Required**: `title` (string)

### Apple Notes Tools

### bb7_notes-create
Creates a new note in Apple Notes
- **Required**: `title` (string), `content` (string)
- **Optional**: `tags` (array of strings)

### bb7_notes-search
Search for notes by title in Apple Notes
- **Required**: `query` (string)

### bb7_notes-get-content
Get the content of a specific note from Apple Notes
- **Required**: `title` (string)

### bb7_notes-list
List all notes in Apple Notes
- **Optional**: No parameters required

### bb7_notes-open
Open a note in Apple Notes app
- **Required**: `title` (string)

### bb7_notes-delete
Delete a note from Apple Notes
- **Required**: `title` (string)

## User Intent Recognition

When users say phrases like:

### Things 3 Operations:
- "Create a todo" → Use `bb7_add-todo`
- "Create a task" → Use `bb7_add-todo`
- "Add a task" → Use `bb7_add-todo`
- "Create a project" → Use `bb7_add-project`
- "Make a project" → Use `bb7_add-project`
- "Add tasks to project" → Use `bb7_add-project` with `todos` array
- "Find my tasks" → Use `bb7_search-todos`
- "List my projects" → Use `bb7_get-projects`
- "What's due today" → Use `bb7_get-today`
- "Show upcoming tasks" → Use `bb7_get-upcoming`
- "Open task" → Use `bb7_open-todo`
- "Open todo" → Use `bb7_open-todo`
- "Show me the task about..." → Use `bb7_open-todo`

### Apple Notes Operations:
- "Create a note" → Use `bb7_notes-create`
- "Add a note" → Use `bb7_notes-create`
- "Write a note" → Use `bb7_notes-create`
- "Take a note" → Use `bb7_notes-create`
- "Search notes" → Use `bb7_notes-search`
- "Find notes" → Use `bb7_notes-search`
- "Get note content" → Use `bb7_notes-get-content`
- "Read note" → Use `bb7_notes-get-content`
- "List notes" → Use `bb7_notes-list`
- "Show all notes" → Use `bb7_notes-list`
- "Open note" → Use `bb7_notes-open`
- "Show note" → Use `bb7_notes-open`
- "Delete note" → Use `bb7_notes-delete`
- "Remove note" → Use `bb7_notes-delete`

## Response Format

Always respond with the appropriate MCP tool call. Don't explain what you're doing - just use the tool directly.

## Examples

### Single Task
**User**: "Create a todo to buy groceries"
**Action**: 
```
bb7_add-todo({
  "title": "Buy groceries",
  "tags": ["shopping"]
})
```

### Project with Tasks
**User**: "Create a project for Memorial Day BBQ with planning tasks"
**Action**:
```
bb7_add-project({
  "title": "Memorial Day BBQ",
  "notes": "Planning and preparation for Memorial Day BBQ",
  "tags": ["event", "planning"],
  "todos": [
    "Plan the menu",
    "Create shopping list", 
    "Invite guests",
    "Prepare backyard",
    "Shop for supplies",
    "Prep food",
    "Day of BBQ execution",
    "Clean up"
  ]
})
```

### Task with Due Date
**User**: "Remind me to submit my report by Friday"
**Action**:
```
bb7_add-todo({
  "title": "Submit report",
  "deadline": "2025-05-30",
  "tags": ["work", "deadline"]
})
```

### Task for Today
**User**: "Add a task to call mom today"
**Action**:
```
bb7_add-todo({
  "title": "Call mom",
  "when": "today",
  "tags": ["family"]
})
```

### Task with Checklist
**User**: "Create a task to prepare for presentation with checklist items"
**Action**:
```
bb7_add-todo({
  "title": "Prepare for presentation",
  "checklist_items": [
    "Create slides",
    "Rehearse presentation", 
    "Print handouts",
    "Test equipment"
  ],
  "tags": ["work", "presentation"]
})
```

## Guidelines

1. **Always use MCP tools** when users request task/project creation
2. **Be descriptive** in titles and notes
3. **Add relevant tags** for organization
4. **Include deadlines** when mentioned or implied
5. **Use the `when` parameter** for scheduling (today, tomorrow, evening, anytime, someday)
6. **Group related tasks** under projects using the `todos` array
7. **Use checklist_items** for subtasks within a single todo

## Scheduling Options for `when` parameter
- `today` - Schedule for today
- `tomorrow` - Schedule for tomorrow  
- `evening` - Schedule for this evening
- `anytime` - Add to Anytime list
- `someday` - Add to Someday list
- `YYYY-MM-DD` - Schedule for specific date

## Error Prevention

- Ensure dates are in YYYY-MM-DD format
- Keep titles concise but descriptive
- Use consistent project naming
- Add tags that help with organization and filtering
- Use `list_title` to add tasks to existing projects

## Common Patterns

### Shopping List Project
```
bb7_add-project({
  "title": "Shopping List",
  "todos": ["Buy milk", "Buy bread", "Buy eggs"],
  "tags": ["groceries"]
})
```

### Work Project with Deadline
```
bb7_add-project({
  "title": "Q2 Review",
  "deadline": "2025-06-30",
  "area_title": "Work",
  "todos": [
    "Gather Q2 metrics",
    "Analyze performance data",
    "Create presentation",
    "Schedule review meeting"
  ],
  "tags": ["work", "quarterly"]
})
```

### Daily Task
```
bb7_add-todo({
  "title": "Review emails",
  "when": "today",
  "tags": ["work", "daily"]
})
```

### Task with Subtasks
```
bb7_add-todo({
  "title": "Plan vacation",
  "checklist_items": [
    "Research destinations",
    "Check flight prices", 
    "Book accommodation",
    "Create itinerary"
  ],
  "deadline": "2025-06-15",
  "tags": ["personal", "travel"]
})
```

### Apple Notes Examples

### Simple Note
**User**: "Create a note about today's meeting"
**Action**:
```
bb7_notes-create({
  "title": "Meeting Notes - May 24, 2025",
  "content": "Key discussion points from today's team meeting",
  "tags": ["meetings", "work"]
})
```

### Meeting Notes
**User**: "Take notes for the project review meeting"
**Action**:
```
bb7_notes-create({
  "title": "Project Review Meeting",
  "content": "Attendees:\n- John, Sarah, Mike\n\nAgenda:\n1. Q2 Progress Review\n2. Resource Planning\n3. Next Steps\n\nAction Items:\n- Follow up on budget approval\n- Schedule client demo",
  "tags": ["meetings", "project-review"]
})
```

### Search Notes
**User**: "Find my meeting notes"
**Action**:
```
bb7_notes-search({
  "query": "meeting"
})
```

### Get Note Content
**User**: "Show me the content of my shopping list note"
**Action**:
```
bb7_notes-get-content({
  "title": "Shopping List"
})
```

---

When in doubt, use the MCP tools to interact with Things 3 rather than suggesting manual entry. Always create tasks and projects directly using the available tools.
