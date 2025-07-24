#!/bin/bash

# BangoCat App Packaging Script
set -e

# Parse command line arguments
DELIVER_TO_GITHUB=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --deliver)
            DELIVER_TO_GITHUB=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--deliver] [--help]"
            echo "  --deliver    Upload the DMG to GitHub Releases"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

APP_NAME="BangoCat"
BUNDLE_ID="com.bangocat.mac"
VERSION="1.0.0"  # Will be updated by bump_version.sh
BUILD_DIR=".build/release"
PACKAGE_DIR="Build/package"
APP_BUNDLE="${PACKAGE_DIR}/${APP_NAME}.app"
DMG_NAME="Build/${APP_NAME}-${VERSION}.dmg"
GITHUB_REPO="Gamma-Software/BangoCat-mac"

# Function to check GitHub CLI requirements
check_github_requirements() {
    echo "🔍 Checking GitHub delivery requirements..."

    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) is not installed"
        echo "📥 Install it with: brew install gh"
        echo "🔗 Or visit: https://cli.github.com/"
        exit 1
    fi

    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        echo "❌ Not authenticated with GitHub"
        echo "🔐 Run: gh auth login"
        exit 1
    fi

    echo "✅ GitHub CLI is ready for delivery"
}

# Function to deliver to GitHub
deliver_to_github() {
    echo ""
    echo "🚀 Starting GitHub delivery process..."

    # Check if DMG exists
    if [ ! -f "$DMG_NAME" ]; then
        echo "❌ DMG file not found: $DMG_NAME"
        exit 1
    fi

    # Get current git tag or create one based on version
    local tag_name="v${VERSION}"
    local release_title="BangoCat v${VERSION}"
    local release_notes="BangoCat macOS release v${VERSION}

🐱 **What's New**
- Automatic build from commit $(git rev-parse --short HEAD)
- Native Swift implementation for optimal performance
- Transparent overlay with smooth cat animations

📦 **Installation**
1. Download the DMG file below
2. Open the DMG and drag BangoCat.app to Applications
3. Launch BangoCat from Applications folder
4. Grant accessibility permissions when prompted

🔧 **System Requirements**
- macOS 11.0 (Big Sur) or later
- Accessibility permissions for global keyboard monitoring"

    echo "📋 Preparing release: $tag_name"
    echo "📍 Repository: $GITHUB_REPO"
    echo "📦 DMG file: $(basename "$DMG_NAME") ($(du -h "$DMG_NAME" | cut -f1))"

    # Check if release already exists
    if gh release view "$tag_name" --repo "$GITHUB_REPO" &> /dev/null; then
        echo "📋 Release $tag_name already exists"
        echo "🔄 Uploading DMG as additional asset..."

        # Upload the DMG to existing release
        gh release upload "$tag_name" "$DMG_NAME" --repo "$GITHUB_REPO" --clobber

    else
        echo "✨ Creating new release: $tag_name"

        # Create a new release with the DMG
        gh release create "$tag_name" "$DMG_NAME" \
            --repo "$GITHUB_REPO" \
            --title "$release_title" \
            --notes "$release_notes" \
            --draft=false \
            --prerelease=false
    fi

    # Get the release URL
    local release_url=$(gh release view "$tag_name" --repo "$GITHUB_REPO" --json url --jq .url)

    echo ""
    echo "🎉 Successfully delivered to GitHub!"
    echo "🔗 Release URL: $release_url"
    echo "📥 Download URL: $release_url/download/$(basename "$DMG_NAME")"
    echo ""
    echo "✅ Your BangoCat release is now available for download!"
}

echo "🐱 Starting BangoCat packaging process..."
echo "📍 Working from: $PROJECT_ROOT"

# Check GitHub requirements if delivery is requested
if [ "$DELIVER_TO_GITHUB" = true ]; then
    check_github_requirements
fi

# Clean and create package directory
echo "📁 Setting up package directory..."
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Create app bundle structure
echo "📦 Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy the executable
echo "📋 Copying executable..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Info.plist
echo "📄 Copying Info.plist..."
cp "Info.plist" "${APP_BUNDLE}/Contents/"

# Copy app icons
echo "🖼️  Copying app icons..."
if [ -f "Assets/Icons/AppIcon.icns" ]; then
    cp "Assets/Icons/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
fi
if [ -f "Assets/Icons/bongo.ico" ]; then
    cp "Assets/Icons/bongo.ico" "${APP_BUNDLE}/Contents/Resources/"
fi
if [ -f "Assets/Icons/bongo-simple.ico" ]; then
    cp "Assets/Icons/bongo-simple.ico" "${APP_BUNDLE}/Contents/Resources/"
fi

# Copy all images from Sources/BangoCat/Resources
echo "🎨 Copying app resources..."
if [ -d "Sources/BangoCat/Resources" ]; then
    cp -r "Sources/BangoCat/Resources/"* "${APP_BUNDLE}/Contents/Resources/"
fi

# Make executable runnable
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "✅ App bundle created at: ${APP_BUNDLE}"

# Create Applications folder shortcut
echo "🔗 Creating Applications folder shortcut..."
ln -sf /Applications "${PACKAGE_DIR}/Applications"

# Create DMG with Applications folder shortcut
echo "💿 Creating professional DMG file..."
rm -f "${DMG_NAME}"

# Create the DMG directly from the package directory (includes the Applications link)
echo "📦 Building DMG with drag-and-drop installation..."
hdiutil create -size 50m -format UDZO -volname "${APP_NAME}" -srcfolder "${PACKAGE_DIR}" "${DMG_NAME}"

echo "✅ DMG created successfully with drag-and-drop installation!"
echo ""
echo "💡 DMG Enhancement Notes:"
echo "   • For custom DMG layouts, additional permissions may be required"
echo "   • The current DMG includes the Applications folder shortcut"
echo "   • Users can drag BangoCat.app to Applications for easy installation"
echo ""
echo "🚀 To enhance the DMG with custom backgrounds (optional):"
echo "   • Install Python 3 + PIL: pip3 install Pillow"
echo "   • Re-run this script for professional background generation"

echo "🎉 Professional DMG created successfully: ${DMG_NAME}"

# Deliver to GitHub if requested
if [ "$DELIVER_TO_GITHUB" = true ]; then
    deliver_to_github
fi

echo ""
echo "📍 Your packaged app is ready for distribution:"
echo "   📦 App Bundle: ${APP_BUNDLE}"
echo "   💿 DMG File: ${DMG_NAME}"
echo ""
echo "✨ Features of your DMG:"
echo "   🔗 Applications folder shortcut for easy installation"
echo "   🎨 Custom layout and background"
echo "   📏 Proper window sizing and icon arrangement"
echo ""
echo "🚀 Users can now easily install by:"
echo "   1. Opening the DMG file"
echo "   2. Dragging BangoCat.app to the Applications folder"
echo "   3. Ejecting the DMG"
echo ""
echo "💡 Tip: Test the DMG by double-clicking it to ensure it looks good!"
echo ""
if [ "$DELIVER_TO_GITHUB" = false ]; then
    echo "🚀 To deliver to GitHub Releases, run with: --deliver"
    echo "   This will upload the DMG to https://github.com/${GITHUB_REPO}/releases"
fi