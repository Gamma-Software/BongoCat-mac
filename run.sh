#!/bin/bash

# BangoCat Build Menu Script
# Interactive menu to run different build and package commands

print_info "Sourcing .env file..."
source .env

# Function to show usage
show_usage() {
    echo "🐱 BangoCat Build Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --verify, -v          Verify setup and dependencies"
    echo "  --debug-run, -dr      Build debug app and run"
    echo "  --debug-package, -dp  Build debug app and package"
    echo "  --debug-install, -di  Build debug app, package and install locally"
    echo "  --release-run, -rr    Build release app and run"
    echo "  --release-package, -rp Build release app and package"
    echo "  --release-install, -ri Build release app, package and install locally"
    echo "  --deliver, -d         Bump version, build release and deliver to GitHub"
    echo "  --deliver-push, -dp   Bump version with commit/push, build release and deliver"
    echo "  --help, -h            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --verify"
    echo "  $0 --debug-run"
    echo "  $0 --release-package"
    echo "  $0 --deliver 1.3.0"
    echo ""
    echo "If no arguments are provided, the interactive menu will be shown."
}

# Function to execute the selected option
execute_option() {
    local choice=$1
    local version=$2

    case $choice in
        0)
            echo "🔍 Verifying setup and dependencies..."
            echo ""

            # Check if we're on macOS
            if [[ "$OSTYPE" != "darwin"* ]]; then
                echo "❌ Error: This script is designed for macOS only"
                exit 1
            fi
            echo "✅ macOS detected"

            # Check if Xcode Command Line Tools are installed
            if ! command -v xcodebuild &> /dev/null; then
                echo "❌ Error: Xcode Command Line Tools not found"
                echo "   Please install with: xcode-select --install"
                exit 1
            fi
            echo "✅ Xcode Command Line Tools found"

            # Check Swift version
            if ! command -v swift &> /dev/null; then
                echo "❌ Error: Swift not found"
                exit 1
            fi
            echo "✅ Swift found: $(swift --version | head -n 1)"

            # Check if we're in the right directory
            if [ ! -f "Package.swift" ]; then
                echo "❌ Error: Package.swift not found. Please run this script from the BangoCat-mac directory"
                exit 1
            fi
            echo "✅ Package.swift found"

            # Check if required scripts exist
            required_scripts=("Scripts/build.sh" "Scripts/package_app.sh" "Scripts/bump_version.sh")
            for script in "${required_scripts[@]}"; do
                if [ ! -f "$script" ]; then
                    echo "❌ Error: Required script not found: $script"
                    exit 1
                fi
            done
            echo "✅ All required scripts found"

            # Check if source files exist
            if [ ! -f "Sources/BangoCat/main.swift" ]; then
                echo "❌ Error: Main source file not found: Sources/BangoCat/main.swift"
                exit 1
            fi
            echo "✅ Main source file found"

            # Check if cat images exist
            if [ ! -f "Sources/BangoCat/Resources/Images/base.png" ]; then
                echo "❌ Error: Cat image resources not found"
                exit 1
            fi
            echo "✅ Cat image resources found"

            # Check if Info.plist exists
            if [ ! -f "Info.plist" ]; then
                echo "❌ Error: Info.plist not found"
                exit 1
            fi
            echo "✅ Info.plist found"

            # Try to resolve dependencies
            echo "📦 Resolving Swift Package dependencies..."
            if swift package resolve; then
                echo "✅ Dependencies resolved successfully"
            else
                echo "❌ Error: Failed to resolve dependencies"
                exit 1
            fi

            # Check if we can build the project
            echo "🔨 Testing build process..."
            if swift build --configuration debug; then
                echo "✅ Debug build successful"
            else
                echo "❌ Error: Debug build failed"
                exit 1
            fi

            echo ""
            echo "🎉 All checks passed! Your BangoCat development environment is ready."
            echo "   You can now proceed with building and packaging the app."
            ;;
        1)
            echo "🔨 Building debug app and running..."
            rm -rf ./build; ./Scripts/build.sh; swift run
            ;;
        2)
            echo "📦 Building debug app and packaging..."
            rm -rf ./build; rm -rf ./Build; ./Scripts/build.sh; ./Scripts/package_app.sh --debug
            ;;
        3)
            echo "📦 Building debug app, packaging and installing locally..."
            rm -rf ./build; rm -rf ./Build; ./Scripts/build.sh; ./Scripts/package_app.sh --debug --install_local
            ;;
        4)
            echo "🚀 Building release app and running..."
            rm -rf ./build; ./Scripts/build.sh -r; swift run --configuration release
            ;;
        5)
            echo "🚀 Building release app and packaging..."
            rm -rf ./build; rm -rf ./Build; ./Scripts/build.sh -r; ./Scripts/package_app.sh
            ;;
        6)
            echo "🚀 Building release app, packaging and installing locally..."
            rm -rf ./build; rm -rf ./Build; ./Scripts/build.sh -r; ./Scripts/package_app.sh --install_local
            ;;
        7)
            if [ -z "$version" ]; then
                echo "❌ Version number is required for deliver option!"
                echo "   Usage: $0 --deliver <version>"
                exit 1
            fi
            echo "🏷️  Bumping version to $version, building release and delivering and verifying..."
            rm -rf ./build; rm -rf ./Build; ./Scripts/bump_version.sh $version; ./Scripts/build.sh -r; ./Scripts/package_app.sh --deliver --verify
            ;;
        8)
            if [ -z "$version" ]; then
                echo "❌ Version number is required for deliver-push option!"
                echo "   Usage: $0 --deliver-push <version>"
                exit 1
            fi
            echo "🏷️  Bumping version to $version with commit/push, building release and delivering and verifying..."
            rm -rf ./build; rm -rf ./Build; ./Scripts/bump_version.sh $version --push --commit; ./Scripts/build.sh -r; ./Scripts/package_app.sh --deliver --verify
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
    echo "🐱 BangoCat Build Menu"
    echo "======================"
    echo ""
    echo "Please select an option:"
    echo ""
    echo "0) Verify setup and dependencies"
    echo "1) Build debug app and run"
    echo "2) Build debug app and package"
    echo "3) Build debug app, package and install locally"
    echo "4) Build release app and run"
    echo "5) Build release app and package"
    echo "6) Build release app, package and install locally"
    echo "7) Bump version, build release and deliver to GitHub"
    echo "8) Bump version with commit/push, build release and deliver"
    echo "9) Exit"
    echo ""

    read -p "Enter your choice (0-9): " choice

    case $choice in
        0|1|2|3|4|5|6)
            execute_option $choice
            ;;
        7)
            read -p "Enter version number (e.g., 1.3.0): " version
            if [ -z "$version" ]; then
                echo "❌ Version number is required!"
                exit 1
            fi
            execute_option 7 "$version"
            ;;
        8)
            read -p "Enter version number (e.g., 1.3.0): " version
            if [ -z "$version" ]; then
                echo "❌ Version number is required!"
                exit 1
            fi
            execute_option 8 "$version"
            ;;
        9)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 0-9."
            exit 1
            ;;
    esac
else
    # Parse command line arguments
    case "$1" in
        --verify|-v)
            execute_option 0
            ;;
        --debug-run|-dr)
            execute_option 1
            ;;
        --debug-package|-dp)
            execute_option 2
            ;;
        --debug-install|-di)
            execute_option 3
            ;;
        --release-run|-rr)
            execute_option 4
            ;;
        --release-package|-rp)
            execute_option 5
            ;;
        --release-install|-ri)
            execute_option 6
            ;;
        --deliver|-d)
            if [ -z "$2" ]; then
                echo "❌ Version number is required for deliver option!"
                echo "   Usage: $0 --deliver <version>"
                exit 1
            fi
            execute_option 7 "$2"
            ;;
        --deliver-push|-dp)
            if [ -z "$2" ]; then
                echo "❌ Version number is required for deliver-push option!"
                echo "   Usage: $0 --deliver-push <version>"
                exit 1
            fi
            execute_option 8 "$2"
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