#!/usr/bin/env python3
"""Script to create a comprehensive usage note for the Things 3 + Apple Notes MCP tool"""

from apple_notes import AppleNotesManager

def main():
    # Initialize Apple Notes manager
    notes_manager = AppleNotesManager()
    
    title = "How to Use Things 3 + Apple Notes MCP Tool in VSCode"
    
    content = """🚀 Things 3 + Apple Notes MCP Tool - Usage Guide

<br><br>

📋 OVERVIEW

This unified MCP server integrates Things 3 task management and Apple Notes directly into VSCode through GitHub Copilot.

You can create tasks, projects, and notes using natural language commands.

<br><br>

✅ SETUP REQUIRED

• VSCode MCP configuration: Add server config to settings.json (see README.md)

• Server location: [Your cloned repository directory]

• GitHub Copilot instructions: Available in .github/copilot-instructions.md

<br><br>

💼 THINGS 3 - TASK MANAGEMENT

<br>

🎯 Create Tasks:
"Create a todo to buy groceries"
"Add a task to call mom today"
"Remind me to submit my report by Friday"

<br>

📁 Create Projects:
"Create a project for Memorial Day BBQ with planning tasks"
"Make a vacation planning project"
"Create a work project for Q2 review"

<br>

🔍 Task Management:
"Find my tasks about groceries"
"Show me today's tasks"
"List my upcoming tasks"
"What projects do I have?"

<br>

⚡ Advanced Features:
Due dates: "Create a task due next Friday"
Scheduling: "Add a task for today/tomorrow/evening"
Checklists: "Create a task to prepare presentation with checklist items"
Tags: Automatically added based on context

<br><br>

📝 APPLE NOTES - NOTE TAKING

<br>

✏️ Create Notes:
"Create a note about today's meeting"
"Take notes for the project review"
"Write a note about grocery list"

<br>

🔎 Find Notes:
"Search for my meeting notes"
"Find notes about vacation"
"Show me notes containing 'project'"

<br>

📖 Manage Notes:
"List all my notes"
"Get the content of my shopping list note"
"Delete the old meeting note"

<br><br>

🚀 HOW TO USE

<br>

Method 1: GitHub Copilot Chat

1. Open GitHub Copilot chat in VSCode (Ctrl+Cmd+I)

2. Use natural language:
   "Create a todo to review code tomorrow"
   "Make a note about today's standup meeting"
   "Create a vacation project with travel tasks"

<br>

Method 2: Direct Commands

Ask Copilot to perform specific actions:
• Task creation with deadlines and tags
• Project creation with multiple sub-tasks
• Note creation with structured content
• Search and retrieval operations

<br><br>

📚 EXAMPLES

<br>

🌱 Simple Task
"Create a todo to water plants"
→ Creates task with appropriate tags

<br>

🎉 Project with Tasks
"Create a Memorial Day BBQ project"
→ Creates project with: Plan menu, Create shopping list, Invite guests, Prepare backyard, Shop for supplies, Prep food, Execute BBQ, Clean up

<br>

📅 Meeting Notes
"Create a note for today's team meeting"
→ Creates structured note with date, attendees, agenda, action items

<br>

📆 Task with Deadline
"Remind me to file taxes by April 15th"
→ Creates task with specific deadline

<br><br>

💡 TIPS FOR BEST RESULTS

<br>

1. Be Specific: Include deadlines, context, and priorities

2. Use Natural Language: "tomorrow", "next week", "urgent"

3. Context Matters: Mention work, personal, or project context

4. Batch Operations: "Create a project with these tasks..."

5. Search Effectively: Use keywords that appear in titles/content

<br><br>

⏰ SCHEDULING KEYWORDS

• today, tomorrow, evening
• anytime, someday
• YYYY-MM-DD (specific dates)

<br><br>

🤖 AUTOMATIC FEATURES

• Smart tagging based on content
• Project organization
• Due date parsing
• Content formatting
• iCloud sync (Notes)

<br><br>

🔧 TROUBLESHOOTING

<br>

If tasks don't appear:
• Check Things 3 is running
• Verify iCloud sync is enabled

<br>

If notes don't work:
• Ensure Apple Notes is accessible
• Check AppleScript permissions

<br>

If MCP server issues:
• Restart VSCode
• Check terminal for error messages

<br><br>

⭐ INTEGRATION BENEFITS

• Unified workflow in VSCode
• Natural language interface
• Automatic organization
• Cross-platform sync (iCloud)
• GitHub Copilot intelligence
• No manual app switching

<br><br>

🎛️ AVAILABLE MCP TOOLS

<br>

Things 3 Tools:
• bb7_add-todo - Create tasks
• bb7_add-project - Create projects
• bb7_search-todos - Search tasks
• bb7_update-todo - Update tasks
• bb7_get-projects - List projects
• bb7_get-today - Today's tasks
• bb7_get-upcoming - Upcoming tasks
• bb7_get-anytime - Anytime tasks

<br>

Apple Notes Tools:
• notes-create - Create notes
• notes-search - Search notes
• notes-get-content - Get note content
• notes-list - List all notes
• notes-delete - Delete notes

<br><br>

📅 Last Updated: May 24, 2025
🔖 Version: 1.0"""
    
    # Create the note
    result = notes_manager.create_note(title, content)
    
    if result:
        print("✅ Successfully created comprehensive usage guide note!")
        print(f"📝 Note title: '{title}'")
        print(f"📄 Content length: {len(content)} characters")
    else:
        print("❌ Failed to create usage guide note")

if __name__ == "__main__":
    main()
