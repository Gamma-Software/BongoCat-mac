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

# Update Info.plist
print_info "Updating Info.plist..."
INFO_PLIST="$PROJECT_ROOT/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    print_error "Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Backup Info.plist
cp "$INFO_PLIST" "$INFO_PLIST.backup"

# Update CFBundleShortVersionString (version)
if /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST" 2>/dev/null; then
    print_success "Updated CFBundleShortVersionString to $VERSION"
else
    print_error "Failed to update CFBundleShortVersionString"
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    exit 1
fi

# Update CFBundleVersion (build)
if /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$INFO_PLIST" 2>/dev/null; then
    print_success "Updated CFBundleVersion to $BUILD"
else
    print_error "Failed to update CFBundleVersion"
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    exit 1
fi

# Update Swift source file
print_info "Updating Swift source code..."
SWIFT_FILE="$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift"

if [ ! -f "$SWIFT_FILE" ]; then
    print_error "Swift source file not found at $SWIFT_FILE"
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    exit 1
fi

# Backup Swift file
cp "$SWIFT_FILE" "$SWIFT_FILE.backup"

# Update hardcoded version in Swift
if sed -i '' "s/private let appVersion = \"[^\"]*\"/private let appVersion = \"$VERSION\"/" "$SWIFT_FILE"; then
    print_success "Updated appVersion in Swift to $VERSION"
else
    print_error "Failed to update appVersion in Swift"
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    mv "$SWIFT_FILE.backup" "$SWIFT_FILE"
    exit 1
fi

# Update hardcoded build in Swift
if sed -i '' "s/private let appBuild = \"[^\"]*\"/private let appBuild = \"$BUILD\"/" "$SWIFT_FILE"; then
    print_success "Updated appBuild in Swift to $BUILD"
else
    print_error "Failed to update appBuild in Swift"
    mv "$INFO_PLIST.backup" "$INFO_PLIST"
    mv "$SWIFT_FILE.backup" "$SWIFT_FILE"
    exit 1
fi

# Remove backup files if everything succeeded
rm "$INFO_PLIST.backup" "$SWIFT_FILE.backup"

print_success "All version updates completed successfully!"
echo ""

# Show summary
print_info "Summary of changes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Info.plist → CFBundleShortVersionString: $VERSION"
echo "• Info.plist → CFBundleVersion: $BUILD"
echo "• Swift code → appVersion: $VERSION"
echo "• Swift code → appBuild: $BUILD"
echo ""

# Ask about git tag
read -p "$(echo -e "${YELLOW}🏷️  Create git tag v$VERSION? [y/N]: ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_ROOT"

    # Check if working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Working directory is not clean. Consider committing changes first."
        read -p "$(echo -e "${YELLOW}Continue with tagging anyway? [y/N]: ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping git tag creation"
            exit 0
        fi
    fi

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
echo "  • Commit your changes: git add . && git commit -m 'Bump version to $VERSION ($BUILD)'"
echo "  • Push to remote: git push"
echo "  • Build and test: swift build && swift run"