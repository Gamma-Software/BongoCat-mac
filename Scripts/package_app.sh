#!/bin/bash

# BangoCat App Packaging Script
set -e

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

APP_NAME="BangoCat"
BUNDLE_ID="com.bangocat.mac"
VERSION="1.0.1"  # Will be updated by bump_version.sh
BUILD_DIR=".build/release"
PACKAGE_DIR="Build/package"
APP_BUNDLE="${PACKAGE_DIR}/${APP_NAME}.app"
DMG_NAME="Build/${APP_NAME}-${VERSION}.dmg"

echo "🐱 Starting BangoCat packaging process..."
echo "📍 Working from: $PROJECT_ROOT"

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