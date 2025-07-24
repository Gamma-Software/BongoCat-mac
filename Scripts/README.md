# BangoCat Scripts

This directory contains build and maintenance scripts for the BangoCat project.

## Scripts Overview

### 🔨 `build.sh`
Simple build script for development convenience.

```bash
./Scripts/build.sh
```

**What it does:**
- Runs `swift build` from the project root
- Shows success/failure status with colored output
- Provides next steps after successful build

### 📦 `package_app.sh`
Creates a professional, distributable DMG with drag-and-drop installation.

```bash
./Scripts/package_app.sh
```

**What it does:**
- Builds the project in release mode
- Creates an `.app` bundle with proper structure
- Copies icons, resources, and Info.plist
- **🔗 Creates Applications folder shortcut for easy installation**
- **🎨 Generates professional DMG background with BangoCat branding**
- **📏 Customizes DMG window layout and icon arrangement**
- Creates compressed, read-only DMG for distribution
- Outputs to `Build/` directory

**Professional DMG Features:**
- ✨ Drag-and-drop installation experience
- 🖼️ Custom background with installation instructions
- 📐 Optimized window size (640x400) and layout
- 🎯 Perfect icon positioning (app left, Applications right)
- 🌈 Graceful fallbacks for background generation

**Requirements:**
- Xcode command line tools
- Project must build successfully
- Optional: Python 3 + PIL (for professional background)
- Optional: ImageMagick (for enhanced graphics)

**Output:**
- `Build/package/BangoCat.app` - Ready-to-install app bundle
- `Build/BangoCat-{version}.dmg` - Professional distribution DMG

### 🏷️ `bump_version.sh`
Updates version numbers across the entire project.

```bash
# Using current year.month as build number
./Scripts/bump_version.sh 1.0.2

# With explicit build number
./Scripts/bump_version.sh 1.0.2 2024.12

# Show help
./Scripts/bump_version.sh --help
```

**What it does:**
- Updates `Info.plist` version strings
- Updates hardcoded versions in Swift source
- Updates `package_app.sh` VERSION variable
- Updates DMG background Python script version
- Updates README.md version badge
- Provides colored, detailed output
- Optionally creates git tags
- Creates backups and rolls back on failure
- Shows summary of all changes

**Version Format:**
- Version: `MAJOR.MINOR.PATCH` (e.g., `1.0.2`)
- Build: `YYYY.MM` format (e.g., `2024.12`)

### ✅ `check_version.sh`
Verifies that all version references are consistent across the project.

```bash
# Quick consistency check
./Scripts/check_version.sh

# Detailed output with file locations
./Scripts/check_version.sh --verbose

# Show suggested fixes for inconsistencies
./Scripts/check_version.sh --fix

# Both verbose and fix suggestions
./Scripts/check_version.sh --verbose --fix

# Show help
./Scripts/check_version.sh --help
```

**What it checks:**
- **Info.plist** - CFBundleShortVersionString and CFBundleVersion
- **Swift source** - appVersion and appBuild variables
- **package_app.sh** - VERSION variable
- **DMG background script** - version_text variable
- **README.md** - version badge
- **CHANGELOG.md** - latest version entry

**Exit Codes:**
- `0` - All versions are consistent ✅
- `1` - Version inconsistencies found ❌
- `2` - Script error or missing files ⚠️

**Features:**
- **Smart Analysis** - Separates version numbers from build numbers
- **Detailed Reporting** - Shows exactly which files have mismatches
- **Fix Suggestions** - Recommends commands to resolve inconsistencies
- **Changelog Validation** - Ensures latest changelog entry matches current version
- **Comprehensive Coverage** - Checks all version references in the project

### 🧪 `test.sh`
Comprehensive test runner with advanced features.

```bash
# Run all tests
./Scripts/test.sh

# Verbose output
./Scripts/test.sh --verbose

# Filter specific tests
./Scripts/test.sh --filter StrokeCounter

# Quiet mode (results only)
./Scripts/test.sh --quiet

# Show coverage information
./Scripts/test.sh --coverage

# Show help
./Scripts/test.sh --help
```

**What it does:**
- Runs the complete test suite with colored output
- Provides filtering options for specific test suites
- Shows detailed timing and summary information
- Supports verbose and quiet modes
- Includes coverage reporting setup
- Automatic build checking and parallel execution
- Professional test result formatting

**Test Suites:**
- **StrokeCounterTests**: Counter functionality, persistence, concurrency
- **CatAnimationControllerTests**: Animation logic, state management, input handling
- **AppDelegateTests**: Settings management, per-app positioning, version info
- **BangoCatTests**: Integration tests, memory management, performance

## Usage Examples

### Development Workflow
```bash
# Make changes to code
./Scripts/build.sh                    # Quick build check
./Scripts/test.sh                     # Run comprehensive tests
swift run                            # Test the app

# Before committing
./Scripts/test.sh --verbose          # Run tests with detailed output
./Scripts/test.sh --filter StrokeCounter # Test specific components
./Scripts/check_version.sh           # Verify version consistency

# Ready to release?
./Scripts/test.sh                     # Final test run
./Scripts/check_version.sh --verbose # Detailed version check
./Scripts/bump_version.sh 1.0.2     # Update version
./Scripts/check_version.sh           # Confirm all versions updated
git add . && git commit -m "Release 1.0.2"
git push

./Scripts/package_app.sh             # Create distribution
```

### Release Workflow
```bash
# 1. Pre-release checks
./Scripts/check_version.sh --verbose # Check current version consistency
./Scripts/test.sh                    # Run full test suite

# 2. Bump version and create tag
./Scripts/bump_version.sh 2.0.0     # Follow prompts for git tag

# 3. Verify everything updated correctly
./Scripts/check_version.sh --verbose # Ensure all files updated

# 4. Commit version changes
git add .
git commit -m "Bump version to 2.0.0"
git push
git push origin v2.0.0              # Push the tag

# 5. Create distribution package
./Scripts/package_app.sh

# 6. Upload DMG from Build/ directory
```

### Version Management Best Practices
```bash
# Before any version changes
./Scripts/check_version.sh           # Check current state

# After manual changes to any version references
./Scripts/check_version.sh --fix     # Get fix suggestions

# Automated version bumping (recommended)
./Scripts/bump_version.sh 1.0.3     # Updates everything at once
./Scripts/check_version.sh           # Verify success

# Before major releases
./Scripts/check_version.sh --verbose # Detailed pre-release check
```

## Output Locations

All build outputs go to organized directories:

```
Build/
├── package/                 # App bundle staging
│   └── BangoCat.app        # Complete app bundle
├── BangoCat-1.0.1.dmg      # Distributable DMG
└── (previous builds...)
```

## Troubleshooting

### Build fails
- Ensure you're in the project root
- Check Swift package dependencies: `swift package resolve`
- Clean build: `rm -rf .build && swift build`

### Packaging fails
- Ensure build succeeds first: `./Scripts/build.sh`
- Check that asset files exist in `Assets/Icons/`
- Verify Info.plist is present and valid

### Version bump fails
- Check that you're using proper version format: `X.Y.Z`
- Ensure no uncommitted changes if creating git tags
- Verify file permissions on Info.plist and Swift files

### Version inconsistencies
- Run `./Scripts/check_version.sh --fix` for suggestions
- Use `./Scripts/bump_version.sh` to fix all at once
- Check CHANGELOG.md has the correct latest version entry
- Verify all files are writable and not corrupted

## Script Requirements

All scripts require:
- macOS with bash shell
- Swift toolchain installed
- Xcode command line tools
- Git (for version bump script with tagging)

## Contributing

When adding new scripts:
1. Make them executable: `chmod +x Scripts/new_script.sh`
2. Add colored output using the existing patterns
3. Include error handling and cleanup
4. Update this README with documentation
5. Test from both Scripts/ directory and project root