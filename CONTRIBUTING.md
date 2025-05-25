# Contributing to TaskNote Bridge

Thank you for your interest in contributing to TaskNote Bridge! This document provides guidelines for contributing to the project.

## Development Setup

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/ragdollKB/things-mcp.git
   cd things-mcp
   ```

2. **Set up the development environment**:
   ```bash
   uv venv
   uv pip install -e .
   ```

3. **Run tests to ensure everything works**:
   ```bash
   uv run python test_server.py
   uv run python test_apple_notes.py
   ```

## Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the existing code style

3. **Test your changes**:
   ```bash
   uv run python test_server.py
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add your descriptive commit message"
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request** with a clear description of your changes

## Code Style

- Follow PEP 8 for Python code
- Use descriptive variable and function names
- Add docstrings to functions and classes
- Keep functions focused and modular

## Testing

- Always run the test suite before submitting changes
- Add tests for new functionality
- Ensure all MCP tools work correctly
- Test both Things 3 and Apple Notes integration

## Platform Support

This project is designed for macOS and requires:
- Things 3 app
- Apple Notes app
- AppleScript support

When making changes, consider the macOS-specific nature of the integrations.

## Issues and Bug Reports

When reporting issues, please include:
- Your macOS version
- Things 3 version
- Python version
- Complete error messages
- Steps to reproduce the issue

## Feature Requests

Feature requests are welcome! Please:
- Check if the feature already exists
- Explain the use case clearly
- Consider whether it fits the project's scope

## Getting Help

- Check the README.md for setup instructions
- Review existing issues for similar problems
- Use the GitHub Discussions for questions

Thank you for contributing!
