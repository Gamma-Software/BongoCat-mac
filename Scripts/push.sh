#!/bin/bash

# BongoCat Push Script - GitHub and App Store distribution
set -xe

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}🔍 [VERBOSE] $1${NC}"
    fi
}

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Default values
PUSH_GITHUB=false
PUSH_APP_STORE=false
BUMP_VERSION=""
AUTO_COMMIT=false
AUTO_PUSH=false
VERIFY_ONLY=false
VERBOSE=false

# Function to show usage
show_usage() {
    echo "🚀 BongoCat Push Script"
    echo "======================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Push Options:"
    echo "  --github, -g           Push to GitHub Releases"
    echo "  --app-store, -a        Push to App Store Connect"
    echo "  --all, -A              Push to both GitHub and App Store"
    echo ""
    echo "Version Management:"
    echo "  --bump <version>       Bump version before pushing"
    echo "  --commit, -c           Auto-commit version changes"
    echo "  --push-commit, -p      Auto-push commit to remote"
    echo ""
    echo "Verification:"
    echo "  --verify, -v           Only verify, don't push"
    echo ""
    echo "Debug Options:"
    echo "  --verbose, -V          Enable verbose output for debugging"
    echo ""
    echo "Examples:"
    echo "  $0 --github"
    echo "  $0 --app-store"
    echo "  $0 --bump 1.3.0 --github"
    echo "  $0 --bump 1.3.0 --commit --push-commit --all"
    echo ""
    echo "🔗 GitHub Releases:"
    echo "  • Requires GitHub CLI (gh) or manual upload"
    echo "  • Creates release with DMG and PKG files"
    echo "  • Auto-generates release notes from CHANGELOG.md"
    echo ""
    echo "🍎 App Store Connect:"
echo "  • Requires Apple ID credentials"
echo "  • Requires App Store Connect API access"
echo "  • Uploads PKG file for review"
    echo ""
    echo "📝 Version Management:"
    echo "  • Updates Info.plist version strings"
    echo "  • Updates hardcoded versions in source"
    echo "  • Creates git tag for release"
    echo "  • Optionally commits and pushes changes"
}

# Function to get version from Info.plist
get_version() {
    local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null || echo "1.0.0")
    echo "$version"
}

# Function to bump version
bump_version() {
    local version=$1

    print_info "Bumping version to $version..."

    # Check if bump_version.sh exists
    if [ ! -f "Scripts/bump_version.sh" ]; then
        print_error "bump_version.sh not found"
        return 1
    fi

    # Run bump version script
    local bump_args=""
    if [ "$AUTO_COMMIT" = true ]; then
        bump_args="$bump_args --commit"
    fi
    if [ "$AUTO_PUSH" = true ]; then
        bump_args="$bump_args --push"
    fi

    if ./Scripts/bump_version.sh "$version" $bump_args; then
        print_success "Version bumped to $version"
    else
        print_error "Failed to bump version"
        return 1
    fi
}

# Function to push to GitHub Releases
push_to_github() {
    print_info "Pushing to GitHub Releases..."

    local version=$(get_version)
    local dmg_file="Build/BongoCat-${version}.dmg"
    local pkg_file="Build/BongoCat-${version}.pkg"

    # Check if files exist
    if [ ! -f "$dmg_file" ]; then
        print_error "DMG file not found: $dmg_file"
        print_info "Run ./Scripts/package.sh first"
        return 1
    fi

    # Check if GitHub CLI is available
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) not found"
        print_info "Please install GitHub CLI or upload manually"
        print_info "Files to upload:"
        print_info "  • $dmg_file"
        if [ -f "$pkg_file" ]; then
            print_info "  • $pkg_file"
        fi
        return 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI not authenticated"
        print_info "Run: gh auth login"
        return 1
    fi

    # Create release
    print_info "Creating GitHub release for version $version..."

    # Generate release notes from CHANGELOG.md
    local release_notes=""
    if [ -f "CHANGELOG.md" ]; then
        print_info "Extracting changelog for version $version..."
        print_verbose "Looking for section: ## [$version]"

        # Extract version section from CHANGELOG.md with better pattern matching
        release_notes=$(awk -v version="$version" '
            /^## \[/ && $0 ~ "\\[" version "\\]" {
                in_section = 1
                next
            }
            in_section && /^## \[/ {
                in_section = 0
                exit
            }
            in_section {
                print
            }
        ' CHANGELOG.md)

        if [ -z "$release_notes" ]; then
            print_warning "No changelog section found for version $version"
            print_verbose "Available versions in CHANGELOG.md:"
            print_verbose "$(grep '^## \[' CHANGELOG.md | head -5)"
            release_notes="Release $version"
        else
            print_success "Changelog extracted successfully"
            print_verbose "Changelog content:"
            print_verbose "$release_notes"
        fi
    else
        print_warning "CHANGELOG.md not found"
        release_notes="Release $version"
    fi

    # Create release
    if gh release create "$version" "$dmg_file" "$pkg_file" --title "BongoCat $version" --notes "$release_notes"; then
        print_success "GitHub release created successfully!"
        print_info "Release URL: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/$version"
    else
        print_error "Failed to create GitHub release"
        return 1
    fi
}

# Function to push to App Store Connect
push_to_app_store() {
    print_info "Pushing to App Store Connect..."

    local version
    version=$(get_version)
    local pkg_file="Build/BongoCat-${version}.pkg"
    local zip_file="Build/BongoCat-${version}.pkg.zip"

    # Check if pkg file exists
    if [ ! -f "$pkg_file" ]; then
        print_error "PKG file not found: $pkg_file"
        print_info "Run ./Scripts/package.sh first"
        return 1
    fi

    # Zip the pkg file before upload
    print_info "Zipping PKG before upload..."
    if [ -f "$zip_file" ]; then
        print_verbose "Removing existing zip: $zip_file"
        rm -f "$zip_file"
    fi
    if zip -j "$zip_file" "$pkg_file"; then
        print_success "PKG zipped successfully: $zip_file"
    else
        print_error "Failed to zip PKG file"
        return 1
    fi

    # Check Apple ID credentials
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_APPLE_ID" ]; then
        print_error "Apple ID credentials not set"
        echo ""
        echo "💡 Set environment variables:"
        echo "   export APP_APPLE_ID='1234567890'"
        echo "   export APPLE_ID_PASSWORD='your-app-specific-password'"
        echo "   export TEAM_ID='your-team-id'"
        echo "   export APPLE_ID='your-apple-id@example.com'"
        return 1
    fi

    # Check if pkg is signed
    if ! pkgutil --check-signature "$pkg_file" 2>&1 | grep -q "Signed with a trusted timestamp on: "; then
        print_error "PKG must be signed before App Store upload"
        print_info "Run: ./Scripts/sign.sh --pkg first"
        return 1
    fi

    # Upload to App Store Connect using zipped pkg file
    print_info "Uploading zipped pkg to App Store Connect..."
    print_verbose "Running: xcrun altool --upload-package \"$zip_file\" -t osx --apple-id \"$APP_APPLE_ID\" -u \"$APPLE_ID\" -p \"******\" --bundle-id \"com.leaptech.bongocat\" --bundle-version \"$version\" --bundle-short-version-string \"$version\" --output-format xml"

    local upload_output
    upload_output=$(xcrun altool --upload-package \
        "$zip_file" \
        -t osx \
        --apple-id "$APP_APPLE_ID" \
        -u "$APPLE_ID" \
        -p "$APPLE_ID_PASSWORD" \
        --bundle-id "com.leaptech.bongocat" \
<<<<<<< HEAD
        --bundle-version "$version" \
        --bundle-short-version-string "$version" \
=======
        --bundle-version "\"$version\"" \
        --bundle-short-version-string "\"$version\"" \
>>>>>>> main
        --output-format xml 2>&1)
    local upload_exit_code=$?

    # Always show the output for debugging
    echo "Upload output:"
    echo "$upload_output"
    echo "Exit code: $upload_exit_code"

    if [ $upload_exit_code -eq 0 ] && echo "$upload_output" | grep -q "No errors uploading"; then
        print_success "PKG uploaded to App Store Connect successfully!"
        print_info "Check App Store Connect for processing status"
        print_verbose "Upload details:"
        print_verbose "$(echo "$upload_output" | grep -E "(No errors|RequestUUID|Product ID)")"
    elif echo "$upload_output" | grep -q "No suitable application records were found"; then
        print_error "App not found in App Store Connect"
        echo ""
        echo "💡 Solution: Create the app in App Store Connect first"
        echo ""
        echo "📋 Steps to create the app:"
        echo "   1. Go to https://appstoreconnect.apple.com"
        echo "   2. Click 'My Apps'"
        echo "   3. Click '+' to add a new app"
        echo "   4. Select 'macOS' as platform"
        echo "   5. Enter app details:"
        echo "      • Name: BongoCat"
        echo "      • Bundle ID: com.leaptech.bongocat"
        echo "      • SKU: bongocat-macos (or any unique identifier)"
        echo "   6. Click 'Create'"
        echo "   7. Run this script again"
        return 1
    elif echo "$upload_output" | grep -q "platform iOS App"; then
        print_error "App was created for iOS instead of macOS"
        echo ""
        echo "💡 Solution: Delete the iOS app and create a new macOS app"
        echo ""
        echo "📋 Steps to fix:"
        echo "   1. Go to https://appstoreconnect.apple.com"
        echo "   2. Click 'My Apps'"
        echo "   3. Find your BongoCat app"
        echo "   4. Click '...' next to the app"
        echo "   5. Select 'Delete App'"
        echo "   6. Create a new app:"
        echo "      • Click '+' to add new app"
        echo "      • Select 'macOS' (not iOS!)"
        echo "      • Name: BongoCat"
        echo "      • Bundle ID: com.leaptech.bongocat"
        echo "      • SKU: bongocat-macos"
        echo "   7. Run this script again"
        return 1
    elif echo "$upload_output" | grep -q "ERROR ITMS-"; then
        print_error "Upload failed with ITMS error:"
        echo "$upload_output" | grep "ERROR ITMS-"
        echo ""
        echo "💡 Common solutions:"
        echo "   1. Create the app in App Store Connect first"
        echo "   2. Check that Bundle ID matches: com.leaptech.bongocat"
        echo "   3. Verify app metadata in App Store Connect"
        return 1
    else
        print_error "Upload failed with altool:"
        echo "$upload_output"
        echo ""
        echo "🔍 Debug information:"
        echo "   Exit code: $upload_exit_code"
        echo "   Output length: ${#upload_output} characters"
        return 1
    fi
}

# Function to verify push prerequisites
verify_push_prerequisites() {
    print_info "Verifying push prerequisites..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi

    # Check if we have uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes"
        print_info "Consider committing changes before pushing"
    fi

    # Check if we're on main/master branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        print_warning "Not on main/master branch (current: $current_branch)"
    fi

    # Check if remote is configured
    if ! git remote get-url origin &> /dev/null; then
        print_error "No remote 'origin' configured"
        return 1
    fi

    print_success "Push prerequisites verified"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --github|-g)
            PUSH_GITHUB=true
            shift
            ;;
        --app-store|-a)
            PUSH_APP_STORE=true
            shift
            ;;
        --all|-A)
            PUSH_GITHUB=true
            PUSH_APP_STORE=true
            shift
            ;;
        --bump)
            # Check if next argument is missing or is another flag
            if [[ -z "$2" || "$2" == -* ]]; then
                read -p "Enter version to bump to (e.g., 1.2.3): " input_version
                if [[ -z "$input_version" ]]; then
                    print_error "No version provided for --bump"
                    exit 1
                fi
                BUMP_VERSION="$input_version"
                shift 1
            else
                BUMP_VERSION="$2"
                shift 2
            fi
            ;;
        --commit|-c)
            AUTO_COMMIT=true
            shift
            ;;
        --push-commit|-p)
            AUTO_PUSH=true
            shift
            ;;
        --verify|-v)
            VERIFY_ONLY=true
            shift
            ;;
        --verbose|-V)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# If no specific push target is requested, show help
if [ "$PUSH_GITHUB" = false ] && [ "$PUSH_APP_STORE" = false ] && [ -z "$BUMP_VERSION" ] && [ "$AUTO_COMMIT" = false ] && [ "$AUTO_PUSH" = false ] && [ "$VERIFY_ONLY" = false ] && [ "$VERBOSE" = false ]; then
    show_usage
    exit 0
fi

# Main execution
echo "🚀 BongoCat Push Script"
echo "======================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Please run this script from the BongoCat-mac directory"
    exit 1
fi

# Verify prerequisites
verify_push_prerequisites

# Bump version if requested
if [ -n "$BUMP_VERSION" ]; then
    bump_version "$BUMP_VERSION"
    echo ""
fi

# If only verifying, exit here
if [ "$VERIFY_ONLY" = true ]; then
    print_success "Verification completed successfully!"
    exit 0
fi

# Verify signatures before pushing
if [ "$PUSH_GITHUB" = true ] || [ "$PUSH_APP_STORE" = true ]; then
    echo ""
    print_info "Verifying signatures before push..."
    if ./Scripts/verify.sh --signatures; then
        print_success "Signature verification passed - proceeding with push"
    else
        print_warning "Signature verification failed - push may fail"
        read -p "Continue with push anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Push cancelled due to signature verification failure"
            exit 1
        fi
    fi
fi

# Push to GitHub if requested
if [ "$PUSH_GITHUB" = true ]; then
    push_to_github
    echo ""
fi

# Push to App Store if requested
if [ "$PUSH_APP_STORE" = true ]; then
    push_to_app_store
    echo ""
fi

echo ""
print_success "Push completed successfully!"