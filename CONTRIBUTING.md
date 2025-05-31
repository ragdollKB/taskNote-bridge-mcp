# Contributing to Things MCP Server

Thank you for your interest in contributing to Things MCP Server! This document provides guidelines for contributing to the Swift macOS MCP server project.

## Development Setup

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/ragdollKB/things-mcp.git
   cd things-mcp
   ```

2. **Open the Xcode project**:
   ```bash
   open "Things MCP.xcodeproj"
   ```

3. **Build and test the app**:
   ```bash
   xcodebuild -project "Things MCP.xcodeproj" -scheme "Things MCP" clean build
   ```

## Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following Swift best practices and the project coding guidelines

3. **Test your changes**:
   ```bash
   xcodebuild -project "Things MCP.xcodeproj" -scheme "Things MCP" clean build
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add your descriptive commit message"
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request** with a clear description of your changes

## Code Style

- Follow Swift API Design Guidelines
- Use clear, descriptive naming conventions
- Follow the project's existing code organization
- Add documentation comments for public APIs
- Use proper error handling with Swift's error system
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
