#!/usr/bin/env bash

# BangoCat Version Consistency Checker
# This script verifies that all version references are consistent across the project
set -e

# Ensure we're running in bash (but works with bash 3.2+)
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Restarting with bash..."
    exec bash "$0" "$@"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_detail() { echo -e "${CYAN}   $1${NC}"; }

# Function to show usage
show_usage() {
    echo "BangoCat Version Consistency Checker"
    echo ""
    echo "Usage: $0 [--verbose] [--fix]"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed information about each check"
    echo "  --fix        Suggest commands to fix inconsistencies"
    echo "  --help       Show this help message"
    echo ""
    echo "This script checks:"
    echo "  • Info.plist version strings"
    echo "  • Swift source version variables"
    echo "  • Package script VERSION variable"
    echo "  • DMG background script version"
    echo "  • README.md version badge"
    echo "  • CHANGELOG.md latest version entry"
    echo ""
    echo "Exit codes:"
    echo "  0 - All versions are consistent"
    echo "  1 - Version inconsistencies found"
    echo "  2 - Script error or missing files"
}

# Parse arguments
VERBOSE=false
SUGGEST_FIX=false

for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --fix|-f)
            SUGGEST_FIX=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $arg"
            show_usage
            exit 2
            ;;
    esac
done

print_info "BangoCat Version Consistency Checker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get current directory (should be Scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if $VERBOSE; then
    print_info "Project root: $PROJECT_ROOT"
    echo ""
fi

# Check if we're in the right place
if [ ! -f "$PROJECT_ROOT/Package.swift" ]; then
    print_error "Cannot find Package.swift in parent directory"
    print_error "Make sure to run this script from the Scripts/ directory"
    exit 2
fi

# Arrays to store version information (bash 3.2 compatible)
VERSION_NAMES=()
VERSION_VALUES=()
VERSION_SOURCES=()
BUILD_NAMES=()
BUILD_VALUES=()
BUILD_SOURCES=()

# Function to add version entry
add_version() {
    local name="$1"
    local value="$2"
    local source="$3"

    VERSION_NAMES+=("$name")
    VERSION_VALUES+=("$value")
    VERSION_SOURCES+=("$source")

    if $VERBOSE; then
        print_detail "$name: $value"
    fi
}

# Function to add build entry
add_build() {
    local name="$1"
    local value="$2"
    local source="$3"

    BUILD_NAMES+=("$name")
    BUILD_VALUES+=("$value")
    BUILD_SOURCES+=("$source")

    if $VERBOSE; then
        print_detail "$name: $value"
    fi
}

print_info "Checking version references..."

# Extract versions from all sources

# Info.plist
if [ -f "$PROJECT_ROOT/Info.plist" ]; then
    plist_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_ROOT/Info.plist" 2>/dev/null || echo "")
    plist_build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_ROOT/Info.plist" 2>/dev/null || echo "")

    if [ -n "$plist_version" ]; then
        add_version "Info.plist (CFBundleShortVersionString)" "$plist_version" "$PROJECT_ROOT/Info.plist"
    fi

    if [ -n "$plist_build" ]; then
        add_build "Info.plist (CFBundleVersion)" "$plist_build" "$PROJECT_ROOT/Info.plist"
    fi
else
    print_warning "Info.plist not found"
fi

# Swift source
if [ -f "$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift" ]; then
    swift_version=$(grep -o 'private let appVersion = "[^"]*"' "$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift" | sed 's/.*"\([^"]*\)".*/\1/' || echo "")
    swift_build=$(grep -o 'private let appBuild = "[^"]*"' "$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift" | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

    if [ -n "$swift_version" ]; then
        add_version "Swift appVersion" "$swift_version" "$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift"
    fi

    if [ -n "$swift_build" ]; then
        add_build "Swift appBuild" "$swift_build" "$PROJECT_ROOT/Sources/BangoCat/BangoCatApp.swift"
    fi
else
    print_warning "Swift source file not found"
fi

# package_app.sh
if [ -f "$PROJECT_ROOT/Scripts/package_app.sh" ]; then
    package_version=$(grep -o 'VERSION="[^"]*"' "$PROJECT_ROOT/Scripts/package_app.sh" | sed 's/.*"\([^"]*\)".*/\1/' || echo "")

    if [ -n "$package_version" ]; then
        add_version "package_app.sh VERSION" "$package_version" "$PROJECT_ROOT/Scripts/package_app.sh"
    fi
else
    print_warning "package_app.sh not found"
fi

# DMG script version (with v prefix)
if [ -f "$PROJECT_ROOT/Assets/DMG/create_background.py" ]; then
    dmg_version=$(grep -o 'version_text = "v[^"]*"' "$PROJECT_ROOT/Assets/DMG/create_background.py" | sed 's/version_text = "v\([^"]*\)"/\1/' || echo "")

    if [ -n "$dmg_version" ]; then
        add_version "DMG background script" "$dmg_version" "$PROJECT_ROOT/Assets/DMG/create_background.py"
    fi
else
    print_warning "DMG background script not found"
fi

# README version badge
if [ -f "$PROJECT_ROOT/README.md" ]; then
    readme_version=$(grep -o 'Version-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*-blue' "$PROJECT_ROOT/README.md" | sed 's/Version-\([^-]*\)-blue/\1/' || echo "")

    if [ -n "$readme_version" ]; then
        add_version "README.md badge" "$readme_version" "$PROJECT_ROOT/README.md"
    fi
else
    print_warning "README.md not found"
fi

# CHANGELOG latest version
if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
    changelog_version=$(grep -m 1 -o '## \[[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\]' "$PROJECT_ROOT/CHANGELOG.md" | sed 's/## \[\([^]]*\)\]/\1/' || echo "")

    if [ -n "$changelog_version" ]; then
        add_version "CHANGELOG latest" "$changelog_version" "$PROJECT_ROOT/CHANGELOG.md"
    fi
else
    print_warning "CHANGELOG.md not found"
fi

echo ""
print_info "Analysis Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check version consistency
if [ ${#VERSION_VALUES[@]} -eq 0 ]; then
    print_error "No version references found!"
    exit 2
fi

# Get the first version as reference
reference_version="${VERSION_VALUES[0]}"
reference_name="${VERSION_NAMES[0]}"

print_info "Checking version consistency (reference: $reference_version from $reference_name)..."

version_consistent=true
inconsistencies=()

# Check all versions against reference
for i in "${!VERSION_VALUES[@]}"; do
    current_version="${VERSION_VALUES[$i]}"
    current_name="${VERSION_NAMES[$i]}"

    if [ "$current_version" != "$reference_version" ]; then
        print_error "Version mismatch: $current_name has '$current_version', expected '$reference_version'"
        inconsistencies+=("$current_name: '$current_version' (should be '$reference_version')")
        version_consistent=false
    else
        print_success "$current_name: $current_version ✓"
    fi
done

# Check build consistency (if we have build numbers)
if [ ${#BUILD_VALUES[@]} -gt 0 ]; then
    echo ""
    reference_build="${BUILD_VALUES[0]}"
    reference_build_name="${BUILD_NAMES[0]}"

    print_info "Checking build consistency (reference: $reference_build from $reference_build_name)..."

    for i in "${!BUILD_VALUES[@]}"; do
        current_build="${BUILD_VALUES[$i]}"
        current_build_name="${BUILD_NAMES[$i]}"

        if [ "$current_build" != "$reference_build" ]; then
            print_error "Build mismatch: $current_build_name has '$current_build', expected '$reference_build'"
            inconsistencies+=("$current_build_name: '$current_build' (should be '$reference_build')")
            version_consistent=false
        else
            print_success "$current_build_name: $current_build ✓"
        fi
    done
fi

echo ""

# Final result
if [ ${#inconsistencies[@]} -eq 0 ]; then
    print_success "🎉 All versions are consistent!"
    if $VERBOSE; then
        echo ""
        print_info "Found versions in ${#VERSION_VALUES[@]} locations:"
        for i in "${!VERSION_VALUES[@]}"; do
            print_detail "${VERSION_NAMES[$i]}: ${VERSION_VALUES[$i]} (${VERSION_SOURCES[$i]})"
        done

        if [ ${#BUILD_VALUES[@]} -gt 0 ]; then
            echo ""
            print_info "Found builds in ${#BUILD_VALUES[@]} locations:"
            for i in "${!BUILD_VALUES[@]}"; do
                print_detail "${BUILD_NAMES[$i]}: ${BUILD_VALUES[$i]} (${BUILD_SOURCES[$i]})"
            done
        fi
    fi
    exit 0
else
    print_error "Found ${#inconsistencies[@]} version inconsistencies:"
    echo ""
    for inconsistency in "${inconsistencies[@]}"; do
        print_detail "$inconsistency"
    done

    if $SUGGEST_FIX; then
        echo ""
        print_info "💡 Suggested fix:"
        echo ""
        print_detail "Run the version bump script to fix all inconsistencies:"
        print_detail "  ./Scripts/bump_version.sh $reference_version"
        echo ""
        print_detail "Or manually update the inconsistent files listed above."
    fi

    exit 1
fi