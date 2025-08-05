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
CREATE_DMG=true
CREATE_PKG=true
DEBUG_BUILD=false
APP_STORE=false
DMG_ONLY=false
PKG_ONLY=false

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
    echo "Package Options:"
    echo "  --dmg-only, -d         Create only DMG file"
    echo "  --pkg-only, -p         Create only PKG file"
    echo "  --debug, -D            Package debug build"
    echo "  --app-store, -a        Package for App Store distribution"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --dmg-only"
    echo "  $0 --pkg-only"
    echo "  $0 --debug"
    echo "  $0 --app-store"
    echo ""
    echo "📦 Package Types:"
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
}

# Function to get version from Info.plist
get_version() {
    local version=$(defaults read Info.plist CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
    echo "$version"
}

# Function to get build version from Info.plist
get_build_version() {
    local build_version=$(defaults read Info.plist CFBundleVersion 2>/dev/null || echo "1")
    echo "$build_version"
}

# Function to create app bundle
create_app_bundle() {
    print_info "Creating app bundle..."

    # Get version
    local version=$(get_version)
    local build_version=$(get_build_version)

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

    # Copy resources
    if [ -d "Sources/BongoCat/Resources" ]; then
        cp -R Sources/BongoCat/Resources/* "$app_bundle/Contents/Resources/"
    fi

    # Copy assets
    if [ -d "Assets" ]; then
        cp -R Assets/* "$app_bundle/Contents/Resources/"
    fi

    # Update Info.plist with correct version
    defaults write "$app_bundle/Contents/Info.plist" CFBundleShortVersionString "$version"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleVersion "$build_version"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleExecutable "BongoCat"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleIdentifier "com.leaptech.bongocat"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleName "BongoCat"
    defaults write "$app_bundle/Contents/Info.plist" CFBundlePackageType "APPL"
    defaults write "$app_bundle/Contents/Info.plist" CFBundleSignature "????"
    defaults write "$app_bundle/Contents/Info.plist" LSMinimumSystemVersion "13.0"
    defaults write "$app_bundle/Contents/Info.plist" NSHighResolutionCapable true
    defaults write "$app_bundle/Contents/Info.plist" LSUIElement true

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

    # Check if app bundle exists
    if [ ! -d "$app_bundle" ]; then
        print_error "App bundle not found: $app_bundle"
        print_info "Run ./Scripts/build.sh first"
        return 1
    fi

    # Create DMG
    print_info "Creating DMG: $dmg_name"

    # Remove existing DMG
    if [ -f "$dmg_name" ]; then
        rm "$dmg_name"
    fi

    # Create DMG using hdiutil
    if hdiutil create -volname "BongoCat" -srcfolder "$app_bundle" -ov -format UDZO "$dmg_name"; then
        print_success "DMG created successfully: $dmg_name"
    else
        print_error "Failed to create DMG"
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
while [[ $# -gt 0 ]]; do
    case $1 in
        --dmg-only|-d)
            CREATE_DMG=true
            CREATE_PKG=false
            DMG_ONLY=true
            shift
            ;;
        --pkg-only|-p)
            CREATE_DMG=false
            CREATE_PKG=true
            PKG_ONLY=true
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

# Create app bundle first
create_app_bundle

# Create packages based on options
if [ "$APP_STORE" = true ]; then
    create_app_store_package
elif [ "$CREATE_DMG" = true ]; then
    create_dmg
fi

if [ "$CREATE_PKG" = true ] && [ "$APP_STORE" = false ]; then
    create_pkg
fi

echo ""
print_success "Packaging completed successfully!"

# Verify signatures if files were created
if [ "$CREATE_DMG" = true ] || [ "$CREATE_PKG" = true ] || [ "$APP_STORE" = true ]; then
    echo ""
    print_info "Verifying package signatures..."
    if ./Scripts/verify.sh --signatures; then
        print_success "Package signature verification passed!"
    else
        print_warning "Package signature verification failed or incomplete"
    fi
fi

echo ""
print_info "Created files:"
if [ "$CREATE_DMG" = true ] && [ "$APP_STORE" = false ]; then
    print_info "  • DMG: Build/BongoCat-$(get_version).dmg"
fi
if [ "$CREATE_PKG" = true ] && [ "$APP_STORE" = false ]; then
    print_info "  • PKG: Build/BongoCat-$(get_version).pkg"
fi
if [ "$APP_STORE" = true ]; then
    print_info "  • IPA: Build/BongoCat-$(get_version)-AppStore.ipa"
fi
echo ""
print_info "Next steps:"
if [ "$APP_STORE" = true ]; then
    print_info "  • Sign: ./Scripts/sign.sh --app"
    print_info "  • Upload: ./Scripts/push.sh --app-store"
else
    print_info "  • Sign: ./Scripts/sign.sh --app"
    print_info "  • Push: ./Scripts/push.sh"
fi