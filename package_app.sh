#!/bin/bash

# BangoCat App Packaging Script
set -e

APP_NAME="BangoCat"
BUNDLE_ID="com.bangocat.mac"
VERSION="1.0"
BUILD_DIR=".build/release"
PACKAGE_DIR="package"
APP_BUNDLE="${PACKAGE_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "🐱 Starting BangoCat packaging process..."

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
if [ -f "bongo.ico" ]; then
    cp "bongo.ico" "${APP_BUNDLE}/Contents/Resources/"
fi
if [ -f "bongo-simple.ico" ]; then
    cp "bongo-simple.ico" "${APP_BUNDLE}/Contents/Resources/"
fi

# Copy all images from Sources/BangoCat/Resources
echo "🎨 Copying app resources..."
if [ -d "Sources/BangoCat/Resources" ]; then
    cp -r "Sources/BangoCat/Resources/"* "${APP_BUNDLE}/Contents/Resources/"
fi

# Make executable runnable
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "✅ App bundle created at: ${APP_BUNDLE}"

# Create DMG
echo "💿 Creating DMG file..."
rm -f "${DMG_NAME}"

# Create a temporary DMG
hdiutil create -size 50m -format UDZO -volname "${APP_NAME}" -srcfolder "${PACKAGE_DIR}" "${DMG_NAME}"

echo "🎉 DMG created successfully: ${DMG_NAME}"
echo ""
echo "📍 Your packaged app is ready:"
echo "   App Bundle: ${APP_BUNDLE}"
echo "   DMG File: ${DMG_NAME}"
echo ""
echo "🚀 You can now distribute the DMG file to users!"