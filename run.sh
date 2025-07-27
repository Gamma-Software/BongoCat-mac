#!/bin/bash

# BangoCat Build Menu Script
# Interactive menu to run different build and package commands

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
        read -p "Enter version number (e.g., 1.3.0): " version
        if [ -z "$version" ]; then
            echo "❌ Version number is required!"
            exit 1
        fi
        echo "🏷️  Bumping version to $version, building release and delivering..."
        rm -rf ./build; rm -rf ./Build; ./Scripts/bump_version.sh $version; ./Scripts/build.sh -r; ./Scripts/package_app.sh --deliver
        ;;
    8)
        read -p "Enter version number (e.g., 1.3.0): " version
        if [ -z "$version" ]; then
            echo "❌ Version number is required!"
            exit 1
        fi
        echo "🏷️  Bumping version to $version with commit/push, building release and delivering..."
        rm -rf ./build; rm -rf ./Build; ./Scripts/bump_version.sh $version --push --commit; ./Scripts/build.sh -r; ./Scripts/package_app.sh --deliver
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

echo ""
echo "✅ Operation completed!"