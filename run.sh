#!/bin/bash

# BangoCat Build Menu Script
# Interactive menu to run different build and package commands

echo "🐱 BangoCat Build Menu"
echo "======================"
echo ""
echo "Please select an option:"
echo ""
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

read -p "Enter your choice (1-9): " choice

case $choice in
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
        echo "❌ Invalid option. Please choose 1-9."
        exit 1
        ;;
esac

echo ""
echo "✅ Operation completed!"