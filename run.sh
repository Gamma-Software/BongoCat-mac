#!/bin/bash

# BongoCat Build Menu Script
# Interactive menu to run different build and package commands

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

# Default values
VERBOSE=true

print_info "Sourcing .env file..."
source .env

# Function to show usage
show_usage() {
    echo "🐱 BongoCat Build Menu"
    echo "======================"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Build Options:"
    echo "  --verify, -v          Verify environment and setup"
    echo "  --build, -b           Build app (debug)"
    echo "  --build-debug, -bd    Build app in debug mode"
    echo "  --build-release, -br  Build app in release mode"
    echo "  --test, -t            Run tests"
    echo "  --run, -r             Run the app"
    echo "  --install, -i         Install app locally"
    echo ""
    echo "Package Options:"
    echo "  --package, -p         Package app (DMG and PKG)"
    echo "  --sign, -s            Sign app and notarize"
    echo "  --push, -u            Push to GitHub and/or App Store"
    echo ""
    echo "Combined Workflows:"
    echo "  --debug-all, -da      Build debug, test, run, install"
    echo "  --release-all, -ra    Build release, package, sign, push"
    echo "  --deliver, -d         Complete delivery workflow"
    echo "  --app-store, -as      App Store distribution workflow"
    echo ""
    echo "Version Management:"
    echo "  --check-versions, -cv Check version consistency"
    echo "  --bump-version, -bv   Bump version (requires version number)"
    echo "  --verify-signatures, -vs Verify signatures comprehensively"
    echo ""
    echo "Debug Options:"
    echo "  --verbose, -V         Enable verbose output for debugging"
    echo ""
    echo "Custom Combinations:"
    echo "  --build-test-run, -btr           Build + Test + Run"
    echo "  --build-test-package-sign, -btps Build + Test + Package + Sign"
    echo "  --build-test-package-sign-push, -btpsp Build + Test + Package + Sign + Push"
    echo ""
    echo "Examples:"
    echo "  $0 --verify"
    echo "  $0 --verify --verbose"
    echo "  $0 --build --test"
    echo "  $0 --release-all"
    echo "  $0 --deliver 1.3.0"
    echo "  $0 --check-versions"
    echo "  $0 --bump-version 1.3.0"
    echo "  $0 --build-test-run"
    echo "  $0 --build-package-sign-push"
    echo ""
    echo "🔧 Build Scripts:"
    echo "  • build.sh: Build, test, run, install"
    echo "  • verify.sh: Environment and signature verification"
    echo "  • package.sh: DMG and PKG generation"
    echo "  • sign.sh: Code signing and notarization"
    echo "  • push.sh: GitHub and App Store distribution"
    echo "  • bump_version.sh: Version management"
    echo "  • check_version.sh: Version consistency verification"
    echo ""
    echo "If no arguments are provided, the interactive menu will be shown."
}

# Function to check delivery prerequisites
check_delivery_prerequisites() {
    echo "🔍 Checking delivery prerequisites..."

    # Check for Apple ID credentials for notarization
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
        echo "⚠️  Apple notarization credentials not fully set"
        if [ -z "$APPLE_ID" ]; then
            echo "   • APPLE_ID not set"
        fi
        if [ -z "$APPLE_ID_PASSWORD" ]; then
            echo "   • APPLE_ID_PASSWORD not set"
        fi
        if [ -z "$TEAM_ID" ]; then
            echo "   • TEAM_ID not set"
        fi
        echo "   • App will be delivered without notarization"
        echo "   • Users may see security warnings on first launch"
        echo "   • To enable notarization, set:"
        echo "     export APPLE_ID='your-apple-id@example.com'"
        echo "     export APPLE_ID_PASSWORD='your-app-specific-password'"
        echo "     export TEAM_ID='your-team-id'"
        echo ""
    else
        echo "✅ Apple ID credentials and Team ID found - notarization will be attempted"
    fi

    # Check for code signing certificate
    if [ -f "Scripts/sign.sh" ]; then
        source "Scripts/sign.sh"
        if check_developer_certificate; then
            echo "✅ Apple Developer certificate found"
        else
            echo "⚠️  No Apple Developer certificate found - will use ad-hoc signing"
        fi
    else
        echo "⚠️  Sign script not found"
    fi

    echo ""
}

# Function to execute the selected option
execute_option() {
    local choice=$1
    local version=$2

    case $choice in
        0)
            echo "🔍 Verifying environment and setup..."
            if [ "$VERBOSE" = true ]; then
                ./Scripts/verify.sh --all --verbose
            else
                ./Scripts/verify.sh --all
            fi
            ;;
        1)
            echo "🔨 Building app (debug)..."
            ./Scripts/build.sh --debug
            ;;
        2)
            echo "🔨 Building app (release)..."
            ./Scripts/build.sh --release
            ;;
        3)
            echo "🧪 Running tests..."
            ./Scripts/build.sh --test
            ;;
        4)
            echo "🚀 Running app..."
            ./Scripts/build.sh --run
            ;;
        5)
            echo "📦 Installing app locally..."
            ./Scripts/build.sh --install
            ;;
        6)
            echo "📦 Packaging app..."
            ./Scripts/package.sh
            ;;
        7)
            echo "🔐 Signing app..."
            ./Scripts/sign.sh --app
            ;;
        8)
            echo "🚀 Pushing to distribution..."
            ./Scripts/push.sh
            ;;
        12)
            echo "🔨 Complete debug workflow..."
            ./Scripts/build.sh --all
            ;;
        13)
            echo "🚀 Complete release workflow..."
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🧹 Removing Build folder..."
            rm -rf Build
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🚀 Running: ./Scripts/push.sh --bump --commit --push-commit"
            ./Scripts/push.sh --bump --commit --push-commit
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔨 Running: ./Scripts/build.sh --release --clean"
            ./Scripts/build.sh --release --clean
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📦 Running: ./Scripts/package.sh --app"
            ./Scripts/package.sh --app
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔐 Running: ./Scripts/sign.sh --app"
            ./Scripts/sign.sh --app
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            # ./Scripts/verify.sh --app-store-requirements Done in push.sh
            echo "📦 Running: ./Scripts/package.sh --dmg"
            ./Scripts/package.sh --dmg
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔐 Running: ./Scripts/sign.sh --dmg"
            ./Scripts/sign.sh --dmg
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔐 Running: ./Scripts/sign.sh --notarize-dmg"
            ./Scripts/sign.sh --notarize-dmg
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📦 Running: ./Scripts/package.sh --pkg"
            ./Scripts/package.sh --pkg
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔐 Running: ./Scripts/sign.sh --pkg"
            ./Scripts/sign.sh --pkg
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔍 Running: ./Scripts/verify.sh --signatures"
            ./Scripts/verify.sh --signatures
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🔍 Running: ./Scripts/verify.sh --notarize-dmg"
            ./Scripts/verify.sh --notarize-dmg
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            # ./Scripts/push.sh --github --app-store
            ;;
        14)
            if [ -z "$version" ]; then
                echo "❌ Version number is required for deliver option!"
                echo "   Usage: $0 --deliver <version>"
                exit 1
            fi
            check_delivery_prerequisites
            echo "🏷️  Complete delivery workflow for version $version..."
            ./Scripts/push.sh --bump "$version" --commit --push-commit
            ./Scripts/build.sh --release
            ./Scripts/package.sh
            ./Scripts/sign.sh --all
            ./Scripts/push.sh --all
            ;;
        15)
            echo "🍎 App Store distribution workflow..."
            ./Scripts/build.sh --release
            ./Scripts/package.sh --app-store
            ./Scripts/sign.sh --app
            ./Scripts/push.sh --app-store
            ;;
        *)
            echo "❌ Invalid option."
            exit 1
            ;;
    esac
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments provided, show interactive menu
    echo "🐱 BongoCat Build Menu"
    echo "======================"
    echo ""
    echo "Please select an option:"
    echo ""
    echo "🔧 Build Options:"
echo "0) Verify environment and setup"
echo "1) Build app (debug)"
echo "2) Build app (release)"
echo "3) Run tests"
echo "4) Run app"
echo "5) Install app locally"
    echo ""
    echo "📦 Package Options:"
echo "6) Package app (DMG and PKG)"
echo "7) Sign app"
echo "8) Push to distribution"
    echo ""
    echo "🔍 Verification Options:"
echo "9) Verify signatures comprehensively"
echo "10) Check version consistency"
    echo ""
    echo "🏷️ Version Management:"
echo "11) Bump version (interactive)"
    echo ""
    echo "🚀 Workflows:"
echo "12) Complete debug workflow"
echo "13) Complete release workflow"
echo "14) Complete delivery workflow"
echo "15) App Store distribution workflow"
    echo ""
    echo "🔄 Custom Combinations:"
echo "16) Build + Test + Run"
echo "17) Build + Test + Package + Sign"
echo "18) Build + Test + Package + Sign + Push"
    echo ""
    echo "19) Exit"
    echo ""

    read -p "Enter your choice (0-19): " choice

    case $choice in
        0|1|2|3|4|5|6|7|8)
            execute_option $choice
            ;;
        9)
            echo "🔍 Verifying signatures comprehensively..."
            if [ "$VERBOSE" = true ]; then
                ./Scripts/verify.sh --signatures --verbose
            else
                ./Scripts/verify.sh --signatures
            fi
            ;;
        10)
            echo "🔍 Checking version consistency..."
            ./Scripts/check_version.sh
            ;;
        11)
            echo "🏷️ Bumping version (interactive)..."
            read -p "Enter new version number (e.g., 1.3.0): " version
            if [ -z "$version" ]; then
                echo "❌ Version number is required!"
                exit 1
            fi
            ./Scripts/bump_version.sh "$version"
            ;;
        12|13|14|15)
            execute_option $choice
            ;;
        16)
            echo "🔄 Build + Test + Run workflow..."
            ./Scripts/build.sh --test --run
            ;;
        17)
            echo "🔄 Build + Test + Package + Sign workflow..."
            ./Scripts/build.sh --release --test
            ./Scripts/package.sh
            ./Scripts/sign.sh --app
            ;;
        18)
            echo "🔄 Build + Test + Package + Sign + Push workflow..."
            ./Scripts/build.sh --release --test
            ./Scripts/package.sh
            ./Scripts/sign.sh --app
            ./Scripts/push.sh --github
            ;;
        19)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 0-19."
            exit 1
            ;;
    esac
else
    # Parse command line arguments
    # Handle verbose flag first
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-V)
                VERBOSE=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Reset arguments after processing verbose flag
    set -- "$@"

    case "$1" in
        --verify|-v)
            if [ "$VERBOSE" = true ]; then
                echo "🔍 Verifying environment and setup..."
                ./Scripts/verify.sh --all --verbose
            else
                execute_option 0
            fi
            ;;
        --build|-b)
            execute_option 1
            ;;
        --build-debug|-bd)
            execute_option 1
            ;;
        --build-release|-br)
            execute_option 2
            ;;
        --test|-t)
            execute_option 3
            ;;
        --run|-r)
            execute_option 4
            ;;
        --install|-i)
            execute_option 5
            ;;
        --package|-p)
            execute_option 6
            ;;
        --sign|-s)
            execute_option 7
            ;;
        --push|-u)
            execute_option 8
            ;;
        --debug-all|-da)
            execute_option 12
            ;;
        --release-all|-ra)
            execute_option 13
            ;;
        --deliver|-d)
            if [ -z "$2" ]; then
                echo "❌ Version number is required for deliver option!"
                echo "   Usage: $0 --deliver <version>"
                exit 1
            fi
            execute_option 14 "$2"
            ;;
        --app-store|-as)
            execute_option 15
            ;;
        --check-versions|-cv)
            echo "🔍 Checking version consistency..."
            ./Scripts/check_version.sh
            ;;
        --verify-signatures|-vs)
            echo "🔍 Verifying signatures comprehensively..."
            if [ "$VERBOSE" = true ]; then
                ./Scripts/verify.sh --signatures --verbose
            else
                ./Scripts/verify.sh --signatures
            fi
            ;;
        --bump-version|-bv)
            if [ -z "$2" ]; then
                echo "❌ Version number is required for bump-version option!"
                echo "   Usage: $0 --bump-version <version>"
                exit 1
            fi
            echo "🏷️ Bumping version to $2..."
            ./Scripts/bump_version.sh "$2"
            ;;
        --build-test-run|-btr)
            echo "🔄 Build + Test + Run workflow..."
            ./Scripts/build.sh --test --run
            ;;
        --build-package-sign|-bps)
            echo "🔄 Build + Package + Sign workflow..."
            ./Scripts/build.sh --release
            ./Scripts/package.sh
            ./Scripts/sign.sh --app
            ;;
        --build-package-sign-push|-bpsp)
            echo "🔄 Build + Package + Sign + Push workflow..."
            ./Scripts/build.sh --release
            ./Scripts/package.sh
            ./Scripts/sign.sh --app
            ./Scripts/push.sh --github
            ;;
        --build-test-package-sign|-btps)
            echo "🔄 Build + Test + Package + Sign workflow..."
            ./Scripts/build.sh --release --test
            ./Scripts/package.sh
            ./Scripts/sign.sh --app
            ;;
        --build-test-package-sign-push|-btpsp)
            echo "🔄 Build + Test + Package + Sign + Push workflow..."
            ./Scripts/build.sh --release --test
            ./Scripts/package.sh
            ./Scripts/sign.sh --app
            ./Scripts/push.sh --github
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
fi

echo ""
echo "✅ Operation completed!"