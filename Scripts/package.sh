#!/bin/bash

# BongoCat Package Script - DMG and PKG generation
set -e

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

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Default values
CREATE_APP=false
CREATE_DMG=false
CREATE_PKG=false
DEBUG_BUILD=false
APP_STORE=false

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Function to show usage
show_usage() {
    echo "📦 BongoCat Package Script"
    echo "=========================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "⚠️  REQUIRED: Choose one or more package type options"
    echo ""
    echo "Package Options:"
    echo "  --app, -A         Create APP bundle"
    echo "  --dmg, -d         Create DMG file"
    echo "  --pkg, -p         Create PKG file"
    echo "  --debug, -D            Package debug build"
    echo "  --app-store, -a        Package for App Store distribution"
    echo ""
    echo "Examples:"
    echo "  $0 --app              # Create app bundle only"
    echo "  $0 --dmg              # Create DMG only"
    echo "  $0 --pkg              # Create PKG only"
    echo "  $0 --app --dmg        # Create both app bundle and DMG"
    echo "  $0 --app --pkg        # Create both app bundle and PKG"
    echo "  $0 --dmg --pkg        # Create both DMG and PKG"
    echo "  $0 --app --dmg --pkg  # Create all three package types"
    echo "  $0 --app --debug      # Create debug app bundle"
    echo "  $0 --dmg --debug      # Create debug DMG"
    echo "  $0 --app-store        # Create App Store package"
    echo ""
    echo "📦 Package Types:"
    echo "  • APP: Application bundle (.app)"
    echo "  • DMG: Disk image for direct distribution"
    echo "  • PKG: Installer package for system installation"
    echo "  • App Store: IPA file for App Store Connect"
    echo ""
    echo "🔧 Build Modes:"
    echo "  • Release: Production build (default)"
    echo "  • Debug: Development build with debug symbols"
    echo ""
    echo "🍎 App Store:"
    echo "  • Requires Apple Developer Program membership"
    echo "  • Creates .ipa file ready for App Store Connect"
    echo "  • App will be signed with App Store distribution certificate"
    echo ""
    echo "💡 Tip: Run without arguments to see this help menu"
}

# Function to get version from Info.plist
get_version() {
    local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null || echo "1.0.0")
    echo "$version"
}

# Function to get build version from Info.plist
get_build_version() {
    local build_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist 2>/dev/null || echo "1")
    echo "$build_version"
}

# Function to create app bundle
create_app_bundle() {
    print_info "Creating app bundle..."

    # Get version
    local version=$(get_version)
    local build_version=$(get_version)

    print_info "Version: $version (Build $build_version)"

    # Create Build directory
    mkdir -p Build/package

    # Determine build configuration
    local build_config="release"
    local build_dir=".build/release"
    local app_name="BongoCat"

    if [ "$DEBUG_BUILD" = true ]; then
        build_config="debug"
        build_dir=".build/debug"
        app_name="BongoCat-debug"
    fi

    # Check if build exists
    if [ ! -f "$build_dir/BongoCat" ]; then
        print_error "Build not found: $build_dir/BongoCat"
        print_info "Run ./Scripts/build.sh first"
        return 1
    fi

    # Create app bundle structure
    local app_bundle="Build/package/${app_name}.app"
    mkdir -p "$app_bundle/Contents/MacOS"
    mkdir -p "$app_bundle/Contents/Resources"
    # Copy binary
    cp "$build_dir/BongoCat" "$app_bundle/Contents/MacOS/"
    chmod +x "$app_bundle/Contents/MacOS/BongoCat"

    # Copy Info.plist
    cp Info.plist "$app_bundle/Contents/"

    # Copy resources to the bundle
    if [ -d "Sources/BongoCat/Resources" ]; then
        cp -R Sources/BongoCat/Resources/* "$app_bundle/Contents/Resources/"
    fi

    # Copy assets
    if [ -d "Assets" ]; then
        cp -R Assets/Icons/AppIcon.icns "$app_bundle/Contents/Resources/AppIcon.icns"
        #cp -R Assets/Icons/logo.png "$app_bundle/Contents/Resources/Icons/logo.png"
    fi

    # Update Info.plist with correct version
    defaults write "$app_bundle/Contents/Info.plist" CFBundleShortVersionString "$version"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleVersion "$build_version"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleSignature "????"


    # Add entitlements if they exist
    if [ -f "BongoCat.entitlements" ]; then
        cp BongoCat.entitlements "$app_bundle/Contents/"
    fi

    print_success "App bundle created: $app_bundle"
}

# Function to create DMG
create_dmg() {
    print_info "Creating DMG..."

    local version=$(get_version)
    local app_name="BongoCat"

    if [ "$DEBUG_BUILD" = true ]; then
        app_name="BongoCat-debug"
    fi

    local app_bundle="Build/package/${app_name}.app"
    local dmg_name="Build/BongoCat-${version}.dmg"
    local temp_dmg="Build/BongoCat-temp.dmg"

    # Check if app bundle exists
    if [ ! -d "$app_bundle" ]; then
        print_error "App bundle not found: $app_bundle"
        print_info "Run ./Scripts/build.sh first"
        return 1
    else
        print_info "App bundle found here: $app_bundle"
    fi

    # Create DMG
    print_info "Creating DMG: $dmg_name"

    # Remove existing DMG
    if [ -f "$dmg_name" ]; then
        rm "$dmg_name"
    fi
    if [ -f "$temp_dmg" ]; then
        rm "$temp_dmg"
    fi

    # Create a temporary directory for DMG contents
    local temp_dir="Build/dmg-temp"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"

    # Copy app bundle to temp directory
    cp -R "$app_bundle" "$temp_dir/"

    # Create Applications folder shortcut
    ln -s /Applications "$temp_dir/Applications"

    # Create DMG with the temp directory
    if hdiutil create -volname "BongoCat" -srcfolder "$temp_dir" -ov -format UDZO "$dmg_name"; then
        print_success "DMG created successfully: $dmg_name"

        # Clean up temp directory
        rm -rf "$temp_dir"
    else
        print_error "Failed to create DMG"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to create PKG
create_pkg() {
    print_info "Creating PKG..."

    local version=$(get_version)
    local app_name="BongoCat"

    if [ "$DEBUG_BUILD" = true ]; then
        app_name="BongoCat-debug"
    fi

    local app_bundle="Build/package/${app_name}.app"
    local pkg_name="Build/BongoCat-${version}.pkg"

    # Check if app bundle exists
    if [ ! -d "$app_bundle" ]; then
        print_error "App bundle not found: $app_bundle"
        print_info "Run ./Scripts/build.sh first"
        return 1
    fi

    # Create PKG
    print_info "Creating PKG: $pkg_name"

    # Remove existing PKG
    if [ -f "$pkg_name" ]; then
        rm "$pkg_name"
    fi

    # Create PKG using pkgbuild
    if pkgbuild --component "$app_bundle" --install-location "/Applications" --identifier "com.leaptech.bongocat" --version "$version" "$pkg_name"; then
        print_success "PKG created successfully: $pkg_name"
    else
        print_error "Failed to create PKG"
        return 1
    fi
}

# Function to create App Store package
create_app_store_package() {
    print_info "Creating App Store package..."

    local version=$(get_version)
    local app_name="BongoCat"
    local app_bundle="Build/package/${app_name}.app"
    local ipa_name="Build/BongoCat-${version}-AppStore.ipa"

    # Check if app bundle exists
    if [ ! -d "$app_bundle" ]; then
        print_error "App bundle not found: $app_bundle"
        print_info "Run ./Scripts/build.sh first"
        return 1
    fi

    # Create IPA directory structure
    local ipa_dir="Build/ipa"
    mkdir -p "$ipa_dir/Payload"

    # Copy app bundle to Payload
    cp -R "$app_bundle" "$ipa_dir/Payload/"

    # Create IPA
    print_info "Creating IPA: $ipa_name"

    # Remove existing IPA
    if [ -f "$ipa_name" ]; then
        rm "$ipa_name"
    fi

    # Create IPA using zip
    cd "$ipa_dir"
    if zip -r "../../$ipa_name" .; then
        cd - > /dev/null
        print_success "IPA created successfully: $ipa_name"
    else
        cd - > /dev/null
        print_error "Failed to create IPA"
        return 1
    fi
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --app|-A)
            CREATE_APP=true
            shift
            ;;
        --dmg|-d)
            CREATE_DMG=true
            shift
            ;;
        --pkg|-p)
            CREATE_PKG=true
            shift
            ;;
        --debug|-D)
            DEBUG_BUILD=true
            shift
            ;;
        --app-store|-a)
            APP_STORE=true
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

# Main execution
echo "📦 BongoCat Package Script"
echo "=========================="
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

# Validate that at least one package type option is selected
if [ "$CREATE_APP" != true ] && [ "$CREATE_DMG" != true ] && [ "$CREATE_PKG" != true ] && [ "$APP_STORE" != true ]; then
    print_error "No package type selected. Please choose one of: --app, --dmg, --pkg, or --app-store"
    echo ""
    show_usage
    exit 1
fi


# Check if app bundle is needed and create it if it doesn't exist
app_name="BongoCat"
if [ "$DEBUG_BUILD" = true ]; then
    app_name="BongoCat-debug"
fi
app_bundle="Build/package/${app_name}.app"

if [ "$CREATE_APP" = true ]; then
    if [ ! -d "$app_bundle" ]; then
        print_info "App bundle not found, creating it first..."
        create_app_bundle
    else
        print_info "App bundle already exists: $app_bundle"
    fi
fi

# Create packages based on options
if [ "$CREATE_APP" = true ]; then
    echo ""
    print_success "App bundle creation completed!"
    if [ "$DEBUG_BUILD" = true ]; then
        print_info "Created: Build/package/BongoCat-debug.app"
    else
        print_info "Created: Build/package/BongoCat.app"
    fi
fi

if [ "$APP_STORE" = true ]; then
    create_app_store_package
fi

if [ "$CREATE_DMG" = true ]; then
    create_dmg
fi

if [ "$CREATE_PKG" = true ]; then
    create_pkg
fi

echo ""
print_success "Packaging completed successfully!"



echo ""
print_info "Created files:"
if [ "$CREATE_APP" = true ]; then
    if [ "$DEBUG_BUILD" = true ]; then
        print_info "  • APP: Build/package/BongoCat-debug.app"
    else
        print_info "  • APP: Build/package/BongoCat.app"
    fi
fi
if [ "$CREATE_DMG" = true ]; then
    print_info "  • DMG: Build/BongoCat-$(get_version).dmg"
fi
if [ "$CREATE_PKG" = true ]; then
    print_info "  • PKG: Build/BongoCat-$(get_version).pkg"
fi
if [ "$APP_STORE" = true ]; then
    print_info "  • IPA: Build/BongoCat-$(get_version)-AppStore.ipa"
fi
echo ""
print_info "Next steps:"
if [ "$APP_STORE" = true ]; then
    print_info "  • Upload: ./Scripts/push.sh --app-store"
else
    print_info "  • Push: ./Scripts/push.sh"
fi