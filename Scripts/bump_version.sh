#!/bin/bash

# BangoCat Version Bump Script
# This script updates version numbers across the project
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to show usage
show_usage() {
    echo "BangoCat Version Bump Script"
    echo ""
    echo "Usage: $0 <version> [build]"
    echo ""
    echo "Arguments:"
    echo "  version    Version number (e.g., 1.0.2, 2.1.0)"
    echo "  build      Build number (optional, defaults to YYYY.MM format)"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.2                    # Uses current YYYY.MM as build"
    echo "  $0 1.0.2 2024.12           # Explicit build number"
    echo "  $0 2.0.0 2025.01           # Major version bump"
    echo ""
    echo "This script will:"
    echo "  • Update Info.plist version strings"
    echo "  • Update hardcoded versions in Swift source"
    echo "  • Update package_app.sh VERSION variable"
    echo "  • Update DMG background Python script version"
    echo "  • Update README.md version badge"
    echo "  • Verify all versions are consistent"
    echo "  • Optionally create a git tag"
    echo "  • Show a summary of changes"
}

# Check arguments
if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

VERSION="$1"
BUILD="${2:-$(date +%Y.%m)}"

# Validate version format (basic check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format: $VERSION"
    print_info "Version should be in format: X.Y.Z (e.g., 1.0.2)"
    exit 1
fi

print_info "BangoCat Version Bump Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "New Version: $VERSION"
print_info "New Build:   $BUILD"
echo ""

# Get current directory (should be Scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_info "Project root: $PROJECT_ROOT"
echo ""

# Check if we're in the right place
if [ ! -f "$PROJECT_ROOT/Package.swift" ]; then
    print_error "Cannot find Package.swift in parent directory"
    print_error "Make sure to run this script from the Scripts/ directory"
    exit 1
fi

# Function to create backup and restore on failure
backup_files=()
create_backup() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.backup"
        backup_files+=("$file")
        echo "📋 Created backup: $file.backup"
    fi
}

cleanup_backups() {
    for file in "${backup_files[@]}"; do
        if [ -f "$file.backup" ]; then
            rm "$file.backup"
        fi
    done
}

restore_backups() {
    for file in "${backup_files[@]}"; do
        if [ -f "$file.backup" ]; then
            mv "$file.backup" "$file"
            print_warning "Restored backup: $file"
        fi
    done
}

# Update Info.plist
print_info "Updating Info.plist..."
INFO_PLIST="$PROJECT_ROOT/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    print_error "Info.plist not found at $INFO_PLIST"
    exit 1
fi

create_backup "$INFO_PLIST"

# Update CFBundleShortVersionString (version)
if /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST" 2>/dev/null; then
    print_success "Updated CFBundleShortVersionString to $VERSION"
else
    print_error "Failed to update CFBundleShortVersionString"
    restore_backups
    exit 1
fi

# Update CFBundleVersion (build)
if /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$INFO_PLIST" 2>/dev/null; then
    print_success "Updated CFBundleVersion to $BUILD"
else
    print_error "Failed to update CFBundleVersion"
    restore_backups
    exit 1
fi

# Update Swift source file
print_info "Updating Swift source code..."
SWIFT_FILE="$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift"

if [ ! -f "$SWIFT_FILE" ]; then
    print_error "Swift source file not found at $SWIFT_FILE"
    restore_backups
    exit 1
fi

create_backup "$SWIFT_FILE"

# Update hardcoded version in Swift
if sed -i '' "s/private let appVersion = \"[^\"]*\"/private let appVersion = \"$VERSION\"/" "$SWIFT_FILE"; then
    print_success "Updated appVersion in Swift to $VERSION"
else
    print_error "Failed to update appVersion in Swift"
    restore_backups
    exit 1
fi

# Update hardcoded build in Swift
if sed -i '' "s/private let appBuild = \"[^\"]*\"/private let appBuild = \"$BUILD\"/" "$SWIFT_FILE"; then
    print_success "Updated appBuild in Swift to $BUILD"
else
    print_error "Failed to update appBuild in Swift"
    restore_backups
    exit 1
fi

# Update package_app.sh VERSION variable
print_info "Updating package_app.sh..."
PACKAGE_SCRIPT="$PROJECT_ROOT/Scripts/package_app.sh"

if [ ! -f "$PACKAGE_SCRIPT" ]; then
    print_warning "package_app.sh not found at $PACKAGE_SCRIPT, skipping..."
else
    create_backup "$PACKAGE_SCRIPT"

    if sed -i '' "s/VERSION=\"[^\"]*\"/VERSION=\"$VERSION\"/" "$PACKAGE_SCRIPT"; then
        print_success "Updated VERSION in package_app.sh to $VERSION"
    else
        print_error "Failed to update VERSION in package_app.sh"
        restore_backups
        exit 1
    fi
fi

# Update DMG background Python script
print_info "Updating DMG background script..."
DMG_SCRIPT="$PROJECT_ROOT/Assets/DMG/create_background.py"

if [ ! -f "$DMG_SCRIPT" ]; then
    print_warning "create_background.py not found at $DMG_SCRIPT, skipping..."
else
    create_backup "$DMG_SCRIPT"

    if sed -i '' "s/version_text = \"v[^\"]*\"/version_text = \"v$VERSION\"/" "$DMG_SCRIPT"; then
        print_success "Updated version_text in create_background.py to v$VERSION"
    else
        print_error "Failed to update version_text in create_background.py"
        restore_backups
        exit 1
    fi
fi

# Update README.md version badge
print_info "Updating README.md version badge..."
README_FILE="$PROJECT_ROOT/README.md"

if [ ! -f "$README_FILE" ]; then
    print_warning "README.md not found at $README_FILE, skipping..."
else
    create_backup "$README_FILE"

    if sed -i '' "s/Version-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*-blue/Version-$VERSION-blue/" "$README_FILE"; then
        print_success "Updated version badge in README.md to $VERSION"
    else
        print_error "Failed to update version badge in README.md"
        restore_backups
        exit 1
    fi
fi

# Remove backup files if everything succeeded
cleanup_backups

print_success "All version updates completed successfully!"
echo ""

# Show summary
print_info "Summary of changes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Info.plist → CFBundleShortVersionString: $VERSION"
echo "• Info.plist → CFBundleVersion: $BUILD"
echo "• Swift code → appVersion: $VERSION"
echo "• Swift code → appBuild: $BUILD"
echo "• package_app.sh → VERSION: $VERSION"
echo "• create_background.py → version_text: v$VERSION"
echo "• README.md → version badge: $VERSION"
echo ""

# Verify version consistency before tagging
print_info "Verifying version consistency..."
CHECK_SCRIPT="$SCRIPT_DIR/check_version.sh"

if [ -f "$CHECK_SCRIPT" ]; then
    if "$CHECK_SCRIPT" >/dev/null 2>&1; then
        print_success "✅ Version consistency check passed!"
    else
        print_error "❌ Version consistency check failed!"
        print_warning "Some versions may not have been updated correctly."
        print_info "Running detailed check to show issues:"
        echo ""
        "$CHECK_SCRIPT" --fix
        echo ""
        print_error "Please fix the version inconsistencies before creating a git tag."
        exit 1
    fi
else
    print_warning "Version check script not found at $CHECK_SCRIPT"
    print_info "Skipping consistency verification"
fi

echo ""

# Commit the version bump changes
print_info "Committing version bump changes..."
cd "$PROJECT_ROOT"

# Add all modified files
git add .

# Commit with version bump message
if git commit -m "bump version to v$VERSION"; then
    print_success "Committed version bump changes"
else
    print_warning "Failed to commit changes (might be no changes to commit)"
fi

echo ""

# Ask about git tag
read -p "$(echo -e "${YELLOW}🏷️  Create git tag v$VERSION? [y/N]: ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_ROOT"

    # Create tag
    if git tag -a "v$VERSION" -m "Release version $VERSION (build $BUILD)"; then
        print_success "Created git tag v$VERSION"
        print_info "Push tag with: git push origin v$VERSION"
    else
        print_warning "Failed to create git tag (tag might already exist)"
    fi
else
    print_info "Skipping git tag creation"
fi

echo ""
print_success "Version bump complete! 🎉"
print_info "Don't forget to:"
echo "  • Test the updated version"
echo "  • Push to remote: git push"
echo "  • Build and test: swift build && swift run"