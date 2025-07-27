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
    echo "Usage: $0 <version> [options]"
    echo ""
    echo "Arguments:"
    echo "  version    Version number (e.g., 1.0.2, 2.1.0)"
    echo ""
    echo "Options:"
    echo "  --commit   Automatically commit the version bump changes"
    echo "  --push     Automatically push the commit and tag to remote"
    echo "  -h, --help Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.2                           # Interactive mode"
    echo "  $0 1.0.2 --commit                 # Auto commit"
    echo "  $0 1.0.2 --commit --push          # Auto commit and push"
    echo ""
    echo "This script will:"
    echo "  • Update Info.plist version strings"
    echo "  • Update hardcoded versions in Swift source"
    echo "  • Update package_app.sh VERSION variable"
    echo "  • Update DMG background Python script version"
    echo "  • Update README.md version badge"
    echo "  • Use version + UTC date/time as CFBundleVersion"
    echo "  • Verify all versions are consistent"
    echo "  • Optionally commit, tag and push changes"
    echo "  • Show a summary of changes"
}

# Parse command line arguments
VERSION=""
AUTO_COMMIT=false
AUTO_PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --commit)
            AUTO_COMMIT=true
            shift
            ;;
        --push)
            AUTO_PUSH=true
            shift
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                print_error "Unknown argument: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if version is provided
if [[ -z "$VERSION" ]]; then
    print_error "Version number is required!"
    show_usage
    exit 1
fi

# Validate version format (basic check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format: $VERSION"
    print_info "Version should be in format: X.Y.Z (e.g., 1.0.2)"
    exit 1
fi

print_info "BangoCat Version Bump Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "New Version: $VERSION"
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

# Update CFBundleVersion (temporary placeholder, will be replaced with version + UTC date/time)
TEMP_BUILD="$VERSION.temp"
if /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $TEMP_BUILD" "$INFO_PLIST" 2>/dev/null; then
    print_success "Updated CFBundleVersion to temporary value (will be replaced with version + UTC date/time)"
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

# Update hardcoded build in Swift (temporary placeholder, will be replaced with version + UTC date/time)
if sed -i '' "s/private let appBuild = \"[^\"]*\"/private let appBuild = \"$TEMP_BUILD\"/" "$SWIFT_FILE"; then
    print_success "Updated appBuild in Swift to temporary value (will be replaced with version + UTC date/time)"
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
echo "• Info.plist → CFBundleVersion: will be set to version + UTC date/time"
echo "• Swift code → appVersion: $VERSION"
echo "• Swift code → appBuild: will be set to version + UTC date/time"
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

# Git workflow - commit first to get UTC date/time, then update CFBundleVersion
cd "$PROJECT_ROOT"

SHOULD_COMMIT=false
SHOULD_PUSH=false

if [ "$AUTO_COMMIT" = true ]; then
    SHOULD_COMMIT=true
    if [ "$AUTO_PUSH" = true ]; then
        SHOULD_PUSH=true
    fi
else
    # Interactive mode - ask user
    read -p "$(echo -e "${YELLOW}💾 Commit version bump changes? [y/N]: ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SHOULD_COMMIT=true

        read -p "$(echo -e "${YELLOW}🚀 Push changes and tag to remote? [y/N]: ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SHOULD_PUSH=true
        fi
    fi
fi

if [ "$SHOULD_COMMIT" = true ]; then
    print_info "Committing initial version bump changes..."

    # Add all modified files
    git add .

    # Commit with version bump message
    if git commit -m "bump version to v$VERSION"; then
        print_success "Committed initial version bump changes"

        # Get the UTC date/time in format YYYYMMDDHHMM
        UTC_DATETIME=$(date -u +"%Y%m%d%H%M")
        BUILD_VERSION="$VERSION.$UTC_DATETIME"
        print_info "UTC date/time: $UTC_DATETIME"
        print_info "Build version: $BUILD_VERSION"

        # Now update CFBundleVersion with the version + UTC date/time
        print_info "Updating CFBundleVersion with version + UTC date/time..."

        # Update CFBundleVersion in Info.plist with version + UTC date/time
        if /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$INFO_PLIST" 2>/dev/null; then
            print_success "Updated CFBundleVersion to $BUILD_VERSION"
        else
            print_error "Failed to update CFBundleVersion with version + UTC date/time"
            exit 1
        fi

        # Update appBuild in Swift with version + UTC date/time
        if sed -i '' "s/private let appBuild = \"[^\"]*\"/private let appBuild = \"$BUILD_VERSION\"/" "$SWIFT_FILE"; then
            print_success "Updated appBuild in Swift to $BUILD_VERSION"
        else
            print_error "Failed to update appBuild in Swift with version + UTC date/time"
            exit 1
        fi

        # Commit the CFBundleVersion update
        git add .
        if git commit --amend --no-edit; then
            print_success "Updated commit with final CFBundleVersion"
        else
            print_warning "Failed to amend commit with CFBundleVersion update"
        fi

        # Create git tag
        print_info "Creating git tag v$VERSION..."
        if git tag -a "v$VERSION" -m "Release version $VERSION (build $BUILD_VERSION)"; then
            print_success "Created git tag v$VERSION"
        else
            print_warning "Failed to create git tag (tag might already exist)"
        fi

        # Push if requested
        if [ "$SHOULD_PUSH" = true ]; then
            print_info "Pushing changes to remote..."
            if git push; then
                print_success "Pushed changes to remote"
            else
                print_error "Failed to push changes"
            fi

            print_info "Pushing tag to remote..."
            if git push origin "v$VERSION"; then
                print_success "Pushed tag v$VERSION to remote"
            else
                print_error "Failed to push tag"
            fi
        fi

    else
        print_warning "Failed to commit changes (might be no changes to commit)"
    fi
else
    print_info "Skipping git commit"
    print_warning "CFBundleVersion will use placeholder value until committed"
fi

echo ""
print_success "Version bump complete! 🎉"

if [ "$SHOULD_COMMIT" = false ]; then
    print_info "Don't forget to:"
    echo "  • Commit changes: git add . && git commit -m 'bump version to v$VERSION'"
    echo "  • Create tag: git tag -a v$VERSION -m 'Release version $VERSION'"
    echo "  • Push to remote: git push && git push origin v$VERSION"
elif [ "$SHOULD_PUSH" = false ]; then
    print_info "Don't forget to:"
    echo "  • Push to remote: git push && git push origin v$VERSION"
fi

print_info "Next steps:"
echo "  • Test the updated version"
echo "  • Build and test: swift build && swift run"