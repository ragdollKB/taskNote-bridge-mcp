# 🚀 TaskNote Bridge - GitHub Release Checklist

## Pre-Release Testing
- [ ] App builds successfully with `xcodebuild`
- [ ] Custom icon displays correctly
- [ ] MCP server starts automatically when app launches
- [ ] Things 3 integration works (create task test)
- [ ] Apple Notes integration works (create note test)
- [ ] VS Code MCP integration tested end-to-end

## Release Preparation
- [ ] Update version number in Xcode project
- [ ] Update CHANGELOG.md with new version
- [ ] Update version in `create_release_dmg.sh`
- [ ] Test DMG creation: `./create_release_dmg.sh`
- [ ] Verify DMG contains all necessary files
- [ ] Test DMG installation on clean system

## GitHub Repository Setup
- [ ] Repository is public
- [ ] README.md updated with download instructions
- [ ] INSTALLATION.md is complete and accurate
- [ ] All personal paths removed from documentation
- [ ] License file included and up-to-date

## Release Process
- [ ] Create and push version tag: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] GitHub Actions workflow runs successfully
- [ ] DMG file uploaded to release automatically
- [ ] Release notes are accurate and helpful
- [ ] Download link tested and working

## Post-Release
- [ ] Update README.md with latest release badge
- [ ] Test installation instructions with fresh download
- [ ] Monitor GitHub Issues for user feedback
- [ ] Update project documentation if needed

## Optional Enhancements
- [ ] Code signing with Developer ID (reduces security warnings)
- [ ] Notarization (eliminates security warnings completely)
- [ ] Homebrew cask for `brew install --cask tasknote-bridge`
- [ ] Installation video or screenshots

## Distribution Channels
- [ ] GitHub Releases (primary)
- [ ] Direct link sharing
- [ ] Developer community forums
- [ ] MCP ecosystem listings

---

## Quick Release Commands

```bash
# 1. Build and test
xcodebuild -project "TaskNote Bridge.xcodeproj" -scheme "TaskNote Bridge" clean build

# 2. Create DMG
./create_release_dmg.sh

# 3. Create release
git tag v1.0.0
git push origin v1.0.0

# 4. GitHub Actions will automatically:
#    - Build the app
#    - Create DMG
#    - Create GitHub release
#    - Upload DMG asset
```

### Final Steps for Publication:
1. **Remove VS Code settings.json reference** (this is user-specific)
2. **Test the setup script** on a clean system
3. **Verify all tools work** with the new configuration approach
4. **Build and test TaskNote Bridge.app** using Xcode
5. **Push to public repository** with clean commit history
6. **Tag a release version** (e.g., v1.0.0)

### User Installation Flow:
1. `git clone https://github.com/ragdollKB/taskNote-bridge-mcp`
2. `cd taskNote-bridge-mcp`
3. `uv venv && uv pip install -e .`
4. `uv run python setup_config.py`
5. Follow the configuration instructions
6. **Optional**: Build TaskNote Bridge.app using Xcode for GUI monitoring
7. `uv run python test_server.py` to verify

The codebase is now ready for public release with no personal or computer-specific configurations!
