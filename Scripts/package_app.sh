#!/bin/bash

# BangoCat App Packaging Script
set -e

# Parse command line arguments
DELIVER_TO_GITHUB=false
INSTALL_LOCAL=false
DEBUG_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --deliver)
            DELIVER_TO_GITHUB=true
            shift
            ;;
        --install_local)
            INSTALL_LOCAL=true
            shift
            ;;
        --debug)
            DEBUG_BUILD=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--deliver] [--install_local] [--debug] [--help]"
            echo "  --deliver       Upload the DMG to GitHub Releases"
            echo "  --install_local Install the app directly to /Applications"
            echo "  --debug         Create debug build instead of release build"
            echo "  --help          Show this help message"
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
BUNDLE_ID="com.gammasoftware.bangocat"
VERSION="1.5.0"  # Will be updated by bump_version.sh

# Set build configuration based on debug flag
if [ "$DEBUG_BUILD" = true ]; then
    BUILD_DIR=".build/debug"
    BUILD_TYPE="debug"
    DMG_NAME="Build/${APP_NAME}-${VERSION}-debug.dmg"
    echo "🐛 DEBUG BUILD MODE ENABLED"
    echo "   • Debug symbols included"
    echo "   • No optimizations"
    echo "   • Larger binary size"
    echo ""
else
    BUILD_DIR=".build/release"
    BUILD_TYPE="release"
    DMG_NAME="Build/${APP_NAME}-${VERSION}.dmg"
fi

PACKAGE_DIR="Build/package"
APP_BUNDLE="${PACKAGE_DIR}/${APP_NAME}.app"
GITHUB_REPO="Gamma-Software/BangoCat-mac"

# Function to check if we're on the main branch
check_main_branch() {
    echo "🌿 Checking git branch for GitHub delivery..."

    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [ "$current_branch" != "main" ]; then
        echo "❌ GitHub delivery is only allowed from the main branch"
        echo "📍 Current branch: $current_branch"
        echo "🔄 Please switch to main branch with: git checkout main"
        echo "💡 Or merge your changes to main before delivering to GitHub"
        exit 1
    fi

    echo "✅ On main branch - GitHub delivery is allowed"
}

# Function to check GitHub CLI requirements
check_github_requirements() {
    echo "🔍 Checking GitHub delivery requirements..."

    # Warn about debug builds going to GitHub
    if [ "$DEBUG_BUILD" = true ]; then
        echo ""
        echo "⚠️  WARNING: You're about to deliver a DEBUG build to GitHub!"
        echo "   • Debug builds are larger and slower"
        echo "   • They include debug symbols and are not optimized"
        echo "   • Consider using a release build for public distribution"
        echo ""
        read -p "Are you sure you want to deliver a debug build to GitHub? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ GitHub delivery cancelled"
            exit 1
        fi
    fi

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

# Function to parse changelog for current version
parse_changelog() {
    local version="$1"
    local changelog_file="${PROJECT_ROOT}/CHANGELOG.md"

    if [ ! -f "$changelog_file" ]; then
        echo "⚠️  CHANGELOG.md not found, using default release notes"
        return 1
    fi

    # Extract the section for the current version
    # Look for ## [VERSION] or ## [VERSION] - DATE pattern
    local version_pattern="## \[${version}\]"
    local in_version_section=false
    local changelog_content=""

    while IFS= read -r line; do
        # Check if we found the version header
        if [[ "$line" =~ ^##[[:space:]]*\[${version}\] ]]; then
            in_version_section=true
            continue
        fi

        # Check if we hit the next version section (stop parsing)
        if [[ "$line" =~ ^##[[:space:]]*\[ ]] && [ "$in_version_section" = true ]; then
            break
        fi

        # If we're in the version section, collect the content
        if [ "$in_version_section" = true ]; then
            changelog_content="${changelog_content}${line}"$'\n'
        fi
    done < "$changelog_file"

    if [ -z "$changelog_content" ]; then
        echo "⚠️  No changelog entry found for version ${version}, using default release notes"
        return 1
    fi

    # Clean up the changelog content (remove extra newlines, format for GitHub)
    changelog_content=$(echo "$changelog_content" | sed '/^[[:space:]]*$/d' | head -c 8000)

    echo "$changelog_content"
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
    if [ "$DEBUG_BUILD" = true ]; then
        tag_name="v${VERSION}-debug"
    fi

    local release_title="BangoCat v${VERSION}"
    if [ "$DEBUG_BUILD" = true ]; then
        release_title="BangoCat v${VERSION} (Debug Build)"
    fi

    # Try to parse changelog, fall back to default if parsing fails
    local release_notes
    local changelog_notes
    changelog_notes=$(parse_changelog "${VERSION}")

    if [ $? -eq 0 ] && [ -n "$changelog_notes" ]; then
        # Use changelog content with installation instructions
        local build_info=""
        if [ "$DEBUG_BUILD" = true ]; then
            build_info="

⚠️ **DEBUG BUILD NOTICE**
This is a debug build intended for development and testing purposes:
- Includes debug symbols and logging
- Not optimized for performance
- Larger file size than release builds"
        fi

        release_notes="# BangoCat v${VERSION}${build_info}

${changelog_notes}

## 📦 Installation Instructions

1. Download the DMG file below
2. Open the DMG and drag BangoCat.app to Applications
3. Launch BangoCat from Applications folder
4. Grant accessibility permissions when prompted

## 🔧 System Requirements

- macOS 11.0 (Big Sur) or later
- Accessibility permissions for global keyboard monitoring

---
*Built from commit $(git rev-parse --short HEAD)*"
    else
        # Fall back to default release notes
        local build_notice=""
        if [ "$DEBUG_BUILD" = true ]; then
            build_notice="

⚠️ **DEBUG BUILD** - For development and testing purposes only"
        fi

        release_notes="BangoCat macOS release v${VERSION}${build_notice}

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
    fi

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
            --prerelease=$DEBUG_BUILD
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

# Function to install app locally
install_local() {
    echo ""
    echo "🏠 Starting local installation process..."

    # Check if app bundle exists
    if [ ! -d "$APP_BUNDLE" ]; then
        echo "❌ App bundle not found: $APP_BUNDLE"
        echo "💡 The app bundle should have been created during packaging"
        exit 1
    fi

    local applications_dir="/Applications"
    local target_app="${applications_dir}/${APP_NAME}.app"

    echo "📍 Installing to: $target_app"

    # Check if app already exists
    if [ -d "$target_app" ]; then
        echo "⚠️  Existing installation found"
        echo "🔄 Replacing existing ${APP_NAME}.app in Applications..."

        # Try to quit the app if it's running
        if pgrep -f "${APP_NAME}.app" > /dev/null; then
            echo "🛑 Stopping running ${APP_NAME} processes..."
            pkill -f "${APP_NAME}.app" || true
            sleep 2
        fi

        # Remove existing app (requires sudo if not owned by user)
        if rm -rf "$target_app" 2>/dev/null; then
            echo "✅ Removed existing installation"
        else
            echo "🔐 Existing app requires administrator privileges to remove"
            echo "💡 Please enter your password to replace the existing installation:"
            sudo rm -rf "$target_app"
            echo "✅ Removed existing installation with admin privileges"
        fi
    fi

    # Copy the new app bundle
    echo "📦 Copying ${APP_NAME}.app to Applications..."
    if cp -R "$APP_BUNDLE" "$applications_dir/" 2>/dev/null; then
        echo "✅ Successfully copied app bundle"
    else
        echo "🔐 Installation requires administrator privileges"
        echo "💡 Please enter your password to install to Applications:"
        sudo cp -R "$APP_BUNDLE" "$applications_dir/"
        echo "✅ Successfully installed with admin privileges"
    fi

    # Set proper permissions
    echo "🔧 Setting proper permissions..."
    if chmod -R 755 "$target_app" 2>/dev/null; then
        echo "✅ Permissions set successfully"
    else
        sudo chmod -R 755 "$target_app"
        echo "✅ Permissions set with admin privileges"
    fi

    # Verify installation
    if [ -d "$target_app" ] && [ -x "${target_app}/Contents/MacOS/${APP_NAME}" ]; then
        echo ""
        echo "🎉 Local installation completed successfully!"
        echo "📍 Installed at: $target_app"
        echo "🚀 You can now launch ${APP_NAME} from:"
        echo "   • Applications folder in Finder"
        echo "   • Spotlight search (⌘+Space)"
        echo "   • Dock (if you add it)"
        echo ""
        echo "💡 On first launch, you may need to:"
        echo "   • Allow the app in System Preferences > Security & Privacy"
        echo "   • Grant accessibility permissions for keyboard monitoring"

        # Offer to launch the app
        echo ""
        read -p "🚀 Would you like to launch ${APP_NAME} now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🎊 Launching ${APP_NAME}..."
            open "$target_app"
            echo "✨ ${APP_NAME} should now be starting!"
        fi
    else
        echo "❌ Installation verification failed"
        echo "💡 The app bundle may be corrupted or incomplete"
        exit 1
    fi
}

echo "🐱 Starting BangoCat packaging process..."
echo "📍 Working from: $PROJECT_ROOT"
echo "🔧 Build type: ${BUILD_TYPE}"
echo "📦 Build directory: ${BUILD_DIR}"

# Check if the build directory and executable exist
if [ ! -d "$BUILD_DIR" ] || [ ! -f "${BUILD_DIR}/${APP_NAME}" ]; then
    echo "❌ Build not found at ${BUILD_DIR}/${APP_NAME}"
    echo ""
    echo "💡 You need to build the app first. Run one of:"
    if [ "$DEBUG_BUILD" = true ]; then
        echo "   swift build  # for debug build"
    else
        echo "   swift build -c release  # for release build"
    fi
    echo ""
    echo "🚀 Or use the build script:"
    echo "   ./Scripts/build.sh"
    exit 1
fi

# Check GitHub requirements if delivery is requested
if [ "$DELIVER_TO_GITHUB" = true ]; then
    check_main_branch
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

# Code sign the app bundle for consistent identity
echo "🔐 Code signing app bundle for consistent identity..."
if command -v codesign &> /dev/null; then
    # Try to sign with ad-hoc signature (no certificate required)
    if codesign --force --deep --sign - "${APP_BUNDLE}"; then
        echo "✅ App bundle code signed successfully"
    else
        echo "⚠️  Code signing failed, but app will still work"
        echo "   • Accessibility permissions may need to be re-granted on reinstall"
        echo "   • Consider getting an Apple Developer certificate for production builds"
    fi
else
    echo "⚠️  codesign not available, skipping code signing"
    echo "   • App will work but may require re-granting accessibility permissions"
fi

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

# Install locally if requested
if [ "$INSTALL_LOCAL" = true ]; then
    install_local
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

# Show available options if not used
if [ "$DELIVER_TO_GITHUB" = false ] && [ "$INSTALL_LOCAL" = false ]; then
    echo "🚀 Additional options:"
    echo "   --deliver       Upload to GitHub Releases (https://github.com/${GITHUB_REPO}/releases)"
    echo "   --install_local Install directly to /Applications for testing"
elif [ "$DELIVER_TO_GITHUB" = false ] && [ "$INSTALL_LOCAL" = true ]; then
    echo "🚀 To also deliver to GitHub Releases, run with: --deliver"
    echo "   This will upload the DMG to https://github.com/${GITHUB_REPO}/releases"
elif [ "$DELIVER_TO_GITHUB" = true ] && [ "$INSTALL_LOCAL" = false ]; then
    echo "🏠 To also install locally for testing, run with: --install_local"
    echo "   This will install the app directly to /Applications"
fi