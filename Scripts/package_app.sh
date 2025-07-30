#!/bin/bash

# BangoCat App Packaging Script
set -e

# Parse command line arguments
DELIVER_TO_GITHUB=false
INSTALL_LOCAL=false
DEBUG_BUILD=false
VERIFY_APP=false
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
        --verify)
            VERIFY_APP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--deliver] [--install_local] [--debug] [--verify] [--help]"
            echo "  --deliver       Upload the DMG to GitHub Releases (auto-notarizes release builds)"
            echo "  --install_local Install the app directly to /Applications"
            echo "  --debug         Create debug build instead of release build"
            echo "  --verify        Verify app signature and notarization status"
            echo "  --help          Show this help message"
            echo ""
            echo "📤 Notarization:"
            echo "  • Release builds with --deliver are automatically notarized"
            echo "  • Set APPLE_ID and APPLE_ID_PASSWORD environment variables"
            echo "  • Use app-specific password if 2FA is enabled"
            echo ""
            echo "🔍 Verification:"
            echo "  • --verify alone: Verify local app bundle"
            echo "  • --verify --deliver: Download and verify GitHub release"
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
BUNDLE_ID="com.leaptech.bangocat"
VERSION="1.5.4"  # Will be updated by bump_version.sh

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

# Function to verify app bundle signature and notarization
verify_app_bundle() {
    local app_path="$1"
    local app_name=$(basename "$app_path")

    echo ""
    echo "🔍 Verifying ${app_name}..."
    echo "📍 Path: $app_path"
    echo ""

    # Check if app bundle exists
    if [ ! -d "$app_path" ]; then
        echo "❌ App bundle not found: $app_path"
        return 1
    fi

    # Check if executable exists
    local executable="${app_path}/Contents/MacOS/${APP_NAME}"
    if [ ! -f "$executable" ]; then
        echo "❌ Executable not found: $executable"
        return 1
    fi

    echo "📋 App Bundle Structure:"
    echo "   ✅ App bundle exists"
    echo "   ✅ Executable exists: $(basename "$executable")"
    echo ""

    # Verify code signature
    echo "🔐 Code Signature Verification:"
    if codesign --verify --verbose "$app_path" 2>&1; then
        echo "   ✅ Code signature is valid"
    else
        echo "   ❌ Code signature verification failed"
        return 1
    fi

    # Display signature details
    echo ""
    echo "📄 Signature Details:"
    if codesign --display --verbose "$app_path" 2>&1; then
        echo "   ✅ Signature details retrieved"
    else
        echo "   ❌ Failed to retrieve signature details"
        return 1
    fi

    # Check notarization status
    echo ""
    echo "📤 Notarization Status:"
    if xcrun stapler validate "$app_path" 2>&1; then
        echo "   ✅ App is notarized"
    else
        echo "   ⚠️  App is not notarized (normal for development builds)"
        echo "   💡 For distribution, use --deliver with Apple ID credentials"
    fi

    echo ""
    echo "🎉 Verification completed successfully!"
    return 0
}

# Function to download and verify GitHub release
verify_github_release() {
    echo ""
    echo "🌐 Downloading and verifying GitHub release..."

    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) is not installed"
        echo "📥 Install it with: brew install gh"
        return 1
    fi

    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        echo "❌ Not authenticated with GitHub"
        echo "🔐 Run: gh auth login"
        return 1
    fi

    # Get current version and tag
    local tag_name="v${VERSION}"
    if [ "$DEBUG_BUILD" = true ]; then
        tag_name="v${VERSION}-debug"
    fi

    echo "📋 Checking release: $tag_name"

    # Check if release exists
    if ! gh release view "$tag_name" --repo "$GITHUB_REPO" &> /dev/null; then
        echo "❌ Release $tag_name not found"
        echo "💡 Create a release first with: ./Scripts/package_app.sh --deliver"
        return 1
    fi

    # Get release assets
    echo "📦 Getting release assets..."
    local assets_json=$(gh release view "$tag_name" --repo "$GITHUB_REPO" --json assets)
    local dmg_url=$(echo "$assets_json" | jq -r '.assets[] | select(.name | endswith(".dmg")) | .url' | head -1)

    if [ -z "$dmg_url" ] || [ "$dmg_url" = "null" ]; then
        echo "❌ No DMG asset found in release"
        return 1
    fi

    echo "📥 Downloading DMG from GitHub..."
    local temp_dmg="/tmp/${APP_NAME}-verify.dmg"
    gh release download "$tag_name" --repo "$GITHUB_REPO" --pattern "*.dmg" --output "$temp_dmg"

    if [ ! -f "$temp_dmg" ]; then
        echo "❌ Failed to download DMG"
        return 1
    fi

    echo "✅ DMG downloaded: $(basename "$temp_dmg")"
    echo ""

    # Mount the DMG
    echo "🔗 Mounting DMG..."
    local mount_point=$(hdiutil attach "$temp_dmg" -readonly -nobrowse | grep "/Volumes/" | awk '{print $3}')

    if [ -z "$mount_point" ]; then
        echo "❌ Failed to mount DMG"
        rm -f "$temp_dmg"
        return 1
    fi

    echo "✅ DMG mounted at: $mount_point"

    # Find the app bundle in the mounted DMG
    local app_in_dmg="${mount_point}/${APP_NAME}.app"

    if [ ! -d "$app_in_dmg" ]; then
        echo "❌ App bundle not found in DMG: $app_in_dmg"
        hdiutil detach "$mount_point" 2>/dev/null || true
        rm -f "$temp_dmg"
        return 1
    fi

    # Verify the app bundle
    verify_app_bundle "$app_in_dmg"
    local verify_result=$?

    # Clean up
    echo ""
    echo "🧹 Cleaning up..."
    hdiutil detach "$mount_point" 2>/dev/null || true
    rm -f "$temp_dmg"

    if [ $verify_result -eq 0 ]; then
        echo "✅ GitHub release verification completed successfully!"
        return 0
    else
        echo "❌ GitHub release verification failed"
        return 1
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
if [ -f "Assets/Icons/menu-logo.ico" ]; then
    cp "Assets/Icons/menu-logo.ico" "${APP_BUNDLE}/Contents/Resources/"
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
    # Check for Apple Developer certificate first (updated to include Apple Development)
    if security find-identity -v -p codesigning | grep -q "Developer ID Application\|Mac App Distribution\|Apple Development\|Mac Developer"; then
        echo "🔍 Found Apple Developer certificate, signing with it..."
        # Get the first available certificate (prioritize distribution certificates)
        CERT_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application\|Mac App Distribution\|Apple Development\|Mac Developer" | head -1 | cut -d'"' -f2)
        if codesign --force --deep --sign "$CERT_IDENTITY" "${APP_BUNDLE}"; then
            echo "✅ App bundle signed with Apple Developer certificate"
            echo "   • App should launch without Gatekeeper warnings"
        else
            echo "⚠️  Certificate signing failed, falling back to ad-hoc"
            codesign --force --deep --sign - "${APP_BUNDLE}"
            echo "✅ App bundle signed with ad-hoc signature"
        fi
    else
        # Fall back to ad-hoc signature
        echo "🔍 No Apple Developer certificate found, using ad-hoc signature..."
        if codesign --force --deep --sign - "${APP_BUNDLE}"; then
            echo "✅ App bundle signed with ad-hoc signature"
            echo "   • Users will need to right-click and select 'Open' on first launch"
            echo "   • Consider getting an Apple Developer certificate for production builds"
        else
            echo "⚠️  Code signing failed, but app will still work"
            echo "   • Accessibility permissions may need to be re-granted on reinstall"
        fi
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

# Notarize release builds automatically
if [ "$DEBUG_BUILD" = false ] && [ "$DELIVER_TO_GITHUB" = true ]; then
    echo ""
    echo "📤 Starting automatic notarization for release build..."

    # Check if we have Apple ID credentials for notarization
    if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ]; then
        echo "🔐 Apple ID credentials found, proceeding with notarization..."

        # Check if we have a valid certificate for notarization
        if security find-identity -v -p codesigning | grep -q "Developer ID Application\|Mac App Distribution\|Apple Development\|Mac Developer"; then
            echo "✅ Valid certificate found for notarization"

            # Create a temporary zip for notarization
            temp_zip="/tmp/${APP_NAME}-notarize.zip"
            echo "📦 Creating temporary zip for notarization..."
            ditto -c -k --keepParent "$APP_BUNDLE" "$temp_zip"

            echo "📤 Uploading for notarization..."
            echo "⏳ This may take 5-15 minutes..."

            # Upload for notarization
            upload_output=$(xcrun altool --notarize-app \
                --primary-bundle-id "$BUNDLE_ID" \
                --username "$APPLE_ID" \
                --password "$APPLE_ID_PASSWORD" \
                --file "$temp_zip" 2>&1)

            if echo "$upload_output" | grep -q "RequestUUID"; then
                request_uuid=$(echo "$upload_output" | grep "RequestUUID" | awk '{print $2}')
                echo "✅ Upload successful! Request UUID: $request_uuid"

                echo "⏳ Waiting for notarization to complete..."
                echo "   This can take 5-15 minutes..."

                # Wait for notarization to complete
                attempts=0
                max_attempts=30  # 15 minutes with 30-second intervals
                while [ $attempts -lt $max_attempts ]; do
                    sleep 30
                    attempts=$((attempts + 1))

                    status_output=$(xcrun altool --notarization-info "$request_uuid" \
                        --username "$APPLE_ID" \
                        --password "$APPLE_ID_PASSWORD" 2>&1)

                    if echo "$status_output" | grep -q "Status: success"; then
                        echo "✅ Notarization completed successfully!"

                        # Staple the notarization ticket to the app
                        echo "📎 Stapling notarization ticket to app..."
                        xcrun stapler staple "$APP_BUNDLE"
                        echo "✅ Notarization ticket stapled successfully!"
                        break
                    elif echo "$status_output" | grep -q "Status: invalid"; then
                        echo "❌ Notarization failed!"
                        echo "$status_output"
                        echo "⚠️  Continuing without notarization..."
                        break
                    else
                        echo "⏳ Still processing... (attempt $attempts/$max_attempts)"
                    fi
                done

                if [ $attempts -eq $max_attempts ]; then
                    echo "⚠️  Notarization timeout - continuing without notarization"
                fi

            else
                echo "❌ Upload failed:"
                echo "$upload_output"
                echo "⚠️  Continuing without notarization..."
            fi

            # Clean up
            rm -f "$temp_zip"

        else
            echo "⚠️  No valid certificate found for notarization"
            echo "   • App will be delivered without notarization"
            echo "   • Users may see security warnings on first launch"
        fi

    else
        echo "⚠️  Apple ID credentials not set for notarization"
        echo "💡 To enable notarization, set environment variables:"
        echo "   export APPLE_ID='your-apple-id@example.com'"
        echo "   export APPLE_ID_PASSWORD='your-app-specific-password'"
        echo "   • Use an app-specific password if you have 2FA enabled"
    fi
else
    if [ "$DEBUG_BUILD" = true ]; then
        echo "🐛 Debug build - skipping notarization"
    elif [ "$DELIVER_TO_GITHUB" = false ]; then
        echo "📦 Local build - skipping notarization"
    fi
fi

# Deliver to GitHub if requested
if [ "$DELIVER_TO_GITHUB" = true ]; then
    deliver_to_github
fi

# Install locally if requested
if [ "$INSTALL_LOCAL" = true ]; then
    install_local
fi

# Verify app if requested
if [ "$VERIFY_APP" = true ]; then
    if [ "$DELIVER_TO_GITHUB" = true ]; then
        # Verify GitHub release
        verify_github_release
    else
        # Verify local app bundle
        verify_app_bundle "$APP_BUNDLE"
    fi
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