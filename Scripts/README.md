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
Creates a distributable macOS app bundle and DMG.

```bash
./Scripts/package_app.sh
```

**What it does:**
- Builds the project in release mode
- Creates an `.app` bundle with proper structure
- Copies icons, resources, and Info.plist
- Creates a distributable DMG file
- Outputs to `Build/` directory

**Requirements:**
- Xcode command line tools
- Project must build successfully

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
- Provides colored, detailed output
- Optionally creates git tags
- Creates backups and rolls back on failure
- Shows summary of all changes

**Version Format:**
- Version: `MAJOR.MINOR.PATCH` (e.g., `1.0.2`)
- Build: `YYYY.MM` format (e.g., `2024.12`)

## Usage Examples

### Development Workflow
```bash
# Make changes to code
./Scripts/build.sh                    # Quick build check
swift run                            # Test the app

# Ready to release?
./Scripts/bump_version.sh 1.0.2     # Update version
git add . && git commit -m "Release 1.0.2"
git push

./Scripts/package_app.sh             # Create distribution
```

### Release Workflow
```bash
# 1. Bump version and create tag
./Scripts/bump_version.sh 2.0.0     # Follow prompts for git tag

# 2. Commit version changes
git add .
git commit -m "Bump version to 2.0.0"
git push
git push origin v2.0.0              # Push the tag

# 3. Create distribution package
./Scripts/package_app.sh

# 4. Upload DMG from Build/ directory
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