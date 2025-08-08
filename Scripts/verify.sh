#!/bin/bash

# BongoCat Verify Script - Environment, signatures and build verification
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
print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}🔍 [VERBOSE] $1${NC}"
    fi
}

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Default values
VERIFY_ENVIRONMENT=false
VERIFY_SIGNATURE=false
VERIFY_SIGNATURES=false
VERIFY_NOTARIZATION=false
VERIFY_NOTARIZE_APP=false
VERIFY_NOTARIZE_PKG=false
VERIFY_BUILD=false
VERIFY_VERSIONS=false
VERIFY_APP_STORE_REQUIREMENTS=false
VERIFY_ALL=false
VERBOSE=false

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Function to show usage
show_usage() {
    echo "🔍 BongoCat Verify Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Verification Options:"
    echo "  --environment, -e     Verify development environment setup"
    echo "  --signature, -s       Verify app signature and certificates"
    echo "  --signatures, -S      Verify all signatures comprehensively (app, PKG, DMG)"
    echo "  --notarization, -n    Verify app notarization status"
    echo "  --notarize-dmg, -A    Verify DMG notarization using stapler validate"
    echo "  --notarize-pkg, -P    Verify PKG notarization using stapler validate"
    echo "  --build, -b           Verify build artifacts and dependencies"
    echo "  --versions, -v        Verify version consistency across project"
    echo "  --app-store-requirements Verify app meets App Store requirements using altool"
    echo "  --all, -a             Run all verification checks"
    echo ""
    echo "Debug Options:"
    echo "  --verbose, -V         Enable verbose output for debugging"
    echo ""
    echo "Examples:"
    echo "  $0 --environment"
    echo "  $0 --signature --verbose"
    echo "  $0 --notarize-dmg"
    echo "  $0 --notarize-pkg --verbose"
    echo "  $0 --app-store-requirements"
    echo "  $0 --all --verbose"
    echo ""
    echo "🔧 Environment Check:"
    echo "  • macOS version compatibility"
    echo "  • Xcode Command Line Tools"
    echo "  • Swift version"
    echo "  • Project structure"
    echo "  • Dependencies"
    echo ""
    echo "🔐 Signature Check:"
    echo "  • Code signing certificates"
    echo "  • App bundle signature"
    echo "  • Certificate validity"
    echo "  • Team ID verification"
    echo ""
    echo "📋 Notarization Check:"
    echo "  • App notarization status"
    echo "  • Notarization ticket"
    echo "  • Apple ID credentials"
    echo ""
    echo "🔨 Build Check:"
    echo "  • Build artifacts"
    echo "  • Package dependencies"
    echo "  • Resource files"
    echo "  • Binary integrity"
}

# Function to verify development environment
verify_environment() {
    print_info "Verifying development environment..."
    echo ""

    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        return 1
    fi
    print_success "macOS detected"

    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    print_info "macOS version: $macos_version"
    print_verbose "Full macOS version info: $(sw_vers)"

    # Check if Xcode Command Line Tools are installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode Command Line Tools not found"
        echo "   Please install with: xcode-select --install"
        return 1
    fi
    print_success "Xcode Command Line Tools found"
    print_verbose "Xcode version: $(xcodebuild -version | head -n 1)"

    # Check Swift version
    if ! command -v swift &> /dev/null; then
        print_error "Swift not found"
        return 1
    fi
    local swift_version=$(swift --version | head -n 1)
    print_success "Swift found: $swift_version"
    print_verbose "Full Swift version info:"
    print_verbose "$(swift --version)"

    # Check if we're in the right directory
    if [ ! -f "Package.swift" ]; then
        print_error "Package.swift not found. Please run this script from the BongoCat-mac directory"
        return 1
    fi
    print_success "Package.swift found"
    print_verbose "Current directory: $(pwd)"

    # Check if required scripts exist
    required_scripts=("Scripts/build.sh" "Scripts/package.sh" "Scripts/sign.sh")
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            print_error "Required script not found: $script"
            return 1
        fi
        print_verbose "Found script: $script"
    done
    print_success "All required scripts found"

    # Check if source files exist
    if [ ! -f "Sources/BongoCat/main.swift" ]; then
        print_error "Main source file not found: Sources/BongoCat/main.swift"
        return 1
    fi
    print_success "Main source file found"
    print_verbose "Source files found:"
    print_verbose "$(find Sources/ -name "*.swift" | head -10)"

    # Check if cat images exist
    if [ ! -f "Sources/BongoCat/Resources/Images/base.png" ]; then
        print_error "Cat image resources not found"
        return 1
    fi
    print_success "Cat image resources found"
    print_verbose "Resource files found:"
    print_verbose "$(find Sources/BongoCat/Resources/ -type f | head -10)"

    # Check if Info.plist exists
    if [ ! -f "Info.plist" ]; then
        print_error "Info.plist not found"
        return 1
    fi
    print_success "Info.plist found"
    print_verbose "Info.plist contents preview:"
    print_verbose "$(head -10 Info.plist)"

    # Try to resolve dependencies
    print_info "Resolving Swift Package dependencies..."
    if swift package resolve; then
        print_success "Dependencies resolved successfully"
        print_verbose "Package dependencies:"
        print_verbose "$(swift package show-dependencies | head -20)"
    else
        print_error "Failed to resolve dependencies"
        return 1
    fi

    # Skip the actual build test to avoid long compilation times
    print_info "Skipping build test to avoid long compilation times"
    print_info "Run './Scripts/build.sh' separately to test the build process"
    print_verbose "To test build manually: swift build --configuration debug"

    print_success "Environment verification completed successfully!"
    return 0
}

# Function to verify code signing setup
verify_signature() {
    print_info "Verifying code signing setup..."
    echo ""

    # Check for available certificates
    print_info "Checking available code signing certificates..."
    local certificates=$(security find-identity -v -p codesigning)
    print_verbose "Available certificates:"
    print_verbose "$certificates"

    if echo "$certificates" | grep -q "Developer ID Application"; then
        print_success "Found Developer ID certificate"
    elif echo "$certificates" | grep -q "Mac App Distribution"; then
        print_success "Found Mac App Distribution certificate"
    elif echo "$certificates" | grep -q "Apple Development"; then
        print_warning "Found Apple Development certificate (development only)"
    elif echo "$certificates" | grep -q "Mac Developer"; then
        print_warning "Found Mac Developer certificate (development only)"
    else
        print_warning "No Apple Developer certificate found"
        print_info "Will use ad-hoc signing for distribution"
    fi

    # Check if app bundle exists and verify its signature
    if [ -d "Build/package/BongoCat.app" ]; then
        print_info "Verifying app bundle signature..."
        local app_path="Build/package/BongoCat.app"
        print_verbose "App path: $app_path"

        if codesign -dv "$app_path" 2>&1 | grep -q "TeamIdentifier=$TEAM_ID"; then
            print_success "App bundle is signed"
            print_verbose "App signature details:"
            print_verbose "$(codesign -dv "$app_path" 2>&1)"

            # Check signature validity
            if codesign -v "$app_path" 2>/dev/null; then
                print_success "App signature is valid"
            else
                print_error "App signature is invalid"
                print_verbose "Signature validation output:"
                print_verbose "$(codesign -v "$app_path" 2>&1)"
                return 1
            fi
        else
            print_warning "App bundle is not signed"
            print_verbose "Codesign output:"
            print_verbose "$(codesign -dv "$app_path" 2>&1)"
        fi
    else
        print_info "No app bundle found to verify signature"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type d 2>/dev/null || echo 'No Build directory found')"
    fi

    # Check environment variables for notarization
    print_verbose "Checking environment variables for notarization:"
    print_verbose "APPLE_ID: ${APPLE_ID:-'not set'}"
    print_verbose "APPLE_ID_PASSWORD: ${APPLE_ID_PASSWORD:+'set'}"
    print_verbose "TEAM_ID: ${TEAM_ID:-'not set'}"

    if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
        print_success "Apple ID credentials found for notarization"
    else
        print_warning "Apple ID credentials not fully set for notarization"
        if [ -z "$APPLE_ID" ]; then
            print_info "  • APPLE_ID not set"
        fi
        if [ -z "$APPLE_ID_PASSWORD" ]; then
            print_info "  • APPLE_ID_PASSWORD not set"
        fi
        if [ -z "$TEAM_ID" ]; then
            print_info "  • TEAM_ID not set"
        fi
    fi

    print_success "Signature verification completed!"
    return 0
}

# Function to verify signatures comprehensively
verify_signatures() {
    print_info "Verifying signatures comprehensively..."
    echo ""

    local verification_passed=true

    # Check for available certificates
    print_info "Checking available code signing certificates..."
    local certificates=$(security find-identity -v -p codesigning)
    print_verbose "Available certificates:"
    print_verbose "$certificates"

    if echo "$certificates" | grep -q "Developer ID Application"; then
        print_success "Found Developer ID certificate"
    elif echo "$certificates" | grep -q "Mac App Distribution"; then
        print_success "Found Mac App Distribution certificate"
    elif echo "$certificates" | grep -q "Apple Development"; then
        print_warning "Found Apple Development certificate (development only)"
    elif echo "$certificates" | grep -q "Mac Developer"; then
        print_warning "Found Mac Developer certificate (development only)"
    else
        print_warning "No Apple Developer certificate found"
        print_info "Will use ad-hoc signing for distribution"
    fi

    # Verify app bundle signature
    if [ -d "Build/package/BongoCat.app" ]; then
        print_info "Verifying app bundle signature..."
        local app_path="Build/package/BongoCat.app"
        print_verbose "App path: $app_path"

        if codesign -dv "$app_path" 2>&1 | grep -q "TeamIdentifier=$TEAM_ID" ; then
            print_success "App bundle is signed"

            # Check signature validity
            if codesign -v "$app_path" 2>/dev/null; then
                print_success "App signature is valid"

                # Check signature details
                print_info "App signature details:"
                codesign -dv "$app_path" 2>&1 | grep -E "(Authority|Team|Timestamp)" || true
                print_verbose "Full signature details:"
                print_verbose "$(codesign -dv "$app_path" 2>&1)"
            else
                print_error "App signature is invalid"
                print_verbose "Signature validation output:"
                print_verbose "$(codesign -v "$app_path" 2>&1)"
                verification_passed=false
            fi
        else
            print_warning "App bundle is not signed"
            print_verbose "Codesign output:"
            print_verbose "$(codesign -dv "$app_path" 2>&1)"
        fi
    else
        print_info "No app bundle found to verify signature"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type d 2>/dev/null || echo 'No Build directory found')"
    fi

    # Verify PKG signature
    local pkg_files=$(find Build/ -name "*.pkg" -type f 2>/dev/null)
    print_verbose "Found PKG files: $pkg_files"

    if [ -n "$pkg_files" ]; then
        print_info "Verifying PKG signatures..."
        for pkg_file in $pkg_files; do
            print_info "Checking PKG: $pkg_file"
            print_verbose "PKG file size: $(ls -lh "$pkg_file" | awk '{print $5}')"

            if pkgutil --check-signature "$pkg_file" 2>/dev/null; then
                print_success "PKG signature is valid: $pkg_file"
                print_verbose "PKG signature details:"
                print_verbose "$(pkgutil --check-signature "$pkg_file" 2>&1)"
            else
                print_error "PKG signature is invalid: $pkg_file"
                print_verbose "PKG signature check output:"
                print_verbose "$(pkgutil --check-signature "$pkg_file" 2>&1)"
                verification_passed=false
            fi
        done
    else
        print_info "No PKG files found to verify"
    fi

    # Verify DMG signature
    local dmg_files=$(find Build/ -name "*.dmg" -type f 2>/dev/null)
    print_verbose "Found DMG files: $dmg_files"

    if [ -n "$dmg_files" ]; then
        print_info "Verifying DMG signatures..."
        for dmg_file in $dmg_files; do
            print_info "Checking DMG: $dmg_file"
            print_verbose "DMG file size: $(ls -lh "$dmg_file" | awk '{print $5}')"

            if codesign -v "$dmg_file" 2>/dev/null; then
                print_success "DMG signature is valid: $dmg_file"
                print_verbose "DMG signature details:"
                print_verbose "$(codesign -dv "$dmg_file" 2>&1)"
            else
                print_warning "DMG signature is invalid or missing: $dmg_file"
                print_verbose "DMG signature check output:"
                print_verbose "$(codesign -v "$dmg_file" 2>&1)"
                # DMG files don't always need to be signed
            fi
        done
    else
        print_info "No DMG files found to verify"
    fi

    if [ "$verification_passed" = true ]; then
        print_success "Signature verification completed successfully!"
        return 0
    else
        print_error "Signature verification failed!"
        return 1
    fi
}

# Function to verify notarization
verify_notarization() {
    print_info "Verifying notarization status..."
    echo ""

    # Check if app bundle exists
    if [ ! -d "Build/package/BongoCat.app" ]; then
        print_warning "No app bundle found to verify notarization"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type d 2>/dev/null || echo 'No Build directory found')"
        return 0
    fi

    local app_path="Build/package/BongoCat.app"
    print_verbose "App path: $app_path"

    # Check if app is notarized
    print_info "Checking notarization status..."
    if codesign -dv "$app_path" 2>&1 | grep -q "notarized"; then
        print_success "App is notarized"
        print_verbose "Notarization details:"
        print_verbose "$(codesign -dv "$app_path" 2>&1 | grep -i notar)"
    else
        print_warning "App is not notarized"
        print_info "Notarization is required for distribution outside App Store"
        print_verbose "Codesign output (no notarization found):"
        print_verbose "$(codesign -dv "$app_path" 2>&1)"
    fi

    # Check if we can verify notarization with Apple
    if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ]; then
        print_info "Checking notarization ticket with Apple..."
        print_verbose "Using Apple ID: $APPLE_ID"
        print_verbose "Team ID: ${TEAM_ID:-'not set'}"

        # Get the app's identifier
        local bundle_id=$(defaults read "$app_path/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.leaptech.bongocat")
        print_verbose "Bundle ID: $bundle_id"

        # Try to check notarization status
        if command -v xcrun &> /dev/null; then
            print_verbose "Checking notarization with xcrun notarytool..."
            if xcrun notarytool info "$bundle_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" 2>/dev/null; then
                print_success "Notarization ticket found and valid"
            else
                print_warning "No notarization ticket found or invalid credentials"
                print_verbose "Notarytool output:"
                print_verbose "$(xcrun notarytool info "$bundle_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" 2>&1)"
            fi
        else
            print_warning "xcrun notarytool not available"
        fi
    else
        print_warning "Apple ID credentials not set for notarization verification"
        print_verbose "APPLE_ID: ${APPLE_ID:-'not set'}"
        print_verbose "APPLE_ID_PASSWORD: ${APPLE_ID_PASSWORD:+'set'}"
        print_verbose "TEAM_ID: ${TEAM_ID:-'not set'}"
    fi

    print_success "Notarization verification completed!"
    return 0
}

# Function to verify build artifacts
verify_build() {
    print_info "Verifying build artifacts..."
    echo ""

    # Check if build directory exists
    if [ ! -d ".build" ]; then
        print_warning "No build directory found"
        print_info "Run ./Scripts/build.sh first"
        print_verbose "Current directory contents:"
        print_verbose "$(ls -la | head -10)"
        return 0
    fi

    print_verbose "Build directory contents:"
    print_verbose "$(find .build/ -type f | head -20)"

    # Check for debug build
    if [ -f ".build/debug/BongoCat" ]; then
        print_success "Debug binary found"
        print_verbose "Debug binary size: $(ls -lh ".build/debug/BongoCat" | awk '{print $5}')"
        print_verbose "Debug binary architecture: $(lipo -info ".build/debug/BongoCat" 2>/dev/null || echo 'unknown')"
    fi

    # Check for release build
    if [ -f ".build/release/BongoCat" ]; then
        print_success "Release binary found"
        print_verbose "Release binary size: $(ls -lh ".build/release/BongoCat" | awk '{print $5}')"

        # Check if it's a universal binary
        local archs=$(lipo -info ".build/release/BongoCat" 2>/dev/null | grep -o "x86_64\|arm64" | wc -l)
        if [ "$archs" -eq 2 ]; then
            print_success "Universal binary (Intel + Apple Silicon)"
        else
            print_warning "Single architecture binary"
        fi
        print_verbose "Release binary architecture: $(lipo -info ".build/release/BongoCat" 2>/dev/null || echo 'unknown')"
    fi

    # Check if Build directory exists
    if [ -d "Build" ]; then
        print_success "Build artifacts directory found"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type f | head -20)"

        # Check for app bundle
        if [ -d "Build/package/BongoCat.app" ]; then
            print_success "App bundle found"
            print_verbose "App bundle size: $(du -sh "Build/package/BongoCat.app" | awk '{print $1}')"

            # Check app bundle structure
            if [ -f "Build/package/BongoCat.app/Contents/Info.plist" ]; then
                print_success "App bundle structure is valid"
                print_verbose "App bundle structure:"
                print_verbose "$(find "Build/package/BongoCat.app" -type f | head -10)"
            else
                print_error "App bundle structure is invalid"
                print_verbose "App bundle contents:"
                print_verbose "$(find "Build/package/BongoCat.app" -type f)"
                return 1
            fi
        fi

        # Check for DMG
        if ls Build/*.dmg 1> /dev/null 2>&1; then
            print_success "DMG file found"
            print_verbose "DMG files:"
            print_verbose "$(ls -lh Build/*.dmg)"
        fi

        # Check for PKG
        if ls Build/*.pkg 1> /dev/null 2>&1; then
            print_success "PKG file found"
            print_verbose "PKG files:"
            print_verbose "$(ls -lh Build/*.pkg)"
        fi
    else
        print_info "No Build directory found"
        print_info "Run ./Scripts/package.sh first"
    fi

    # Check package dependencies
    print_info "Verifying package dependencies..."
    if swift package show-dependencies > /dev/null 2>&1; then
        print_success "Package dependencies are valid"
        print_verbose "Package dependencies:"
        print_verbose "$(swift package show-dependencies | head -20)"
    else
        print_error "Package dependencies are invalid"
        return 1
    fi

    print_success "Build verification completed!"
    return 0
}

# Function to verify version consistency
verify_versions() {
    print_info "Verifying version consistency across project..."
    echo ""

    # Check if check_version.sh exists
    if [ ! -f "Scripts/check_version.sh" ]; then
        print_error "check_version.sh not found"
        print_info "Cannot verify version consistency"
        print_verbose "Scripts directory contents:"
        print_verbose "$(ls -la Scripts/)"
        return 1
    fi

    print_verbose "Running version consistency check..."

    # Run version consistency check
    if ./Scripts/check_version.sh >/dev/null 2>&1; then
        print_success "Version consistency check passed!"
        print_info "All version references are consistent across the project"
    else
        print_error "Version consistency check failed!"
        print_warning "Some version references may be inconsistent"
        print_info "Running detailed check to show issues:"
        echo ""
        ./Scripts/check_version.sh --verbose
        echo ""
        print_info "To fix version inconsistencies, run:"
        print_info "  ./Scripts/check_version.sh --fix"
        return 1
    fi

    # Show current version info
    print_info "Current version information:"
    if [ -f "Info.plist" ]; then
        local short_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null || echo "unknown")
        local build_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist 2>/dev/null || echo "unknown")
        print_info "  • Info.plist CFBundleShortVersionString: $short_version"
        print_info "  • Info.plist CFBundleVersion: $build_version"
        print_verbose "Full Info.plist version info:"
        print_verbose "$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null)"
        print_verbose "$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Info.plist 2>/dev/null)"
    fi

    print_success "Version verification completed!"
    return 0
}

# Function to verify DMG notarization using stapler validate
verify_notarize_app() {
    print_info "Verifying DMG notarization using stapler validate..."
    echo ""

    # Check if stapler command is available
    if ! command -v stapler &> /dev/null; then
        print_error "stapler command not found"
        print_info "stapler is part of Xcode Command Line Tools"
        print_info "Please install with: xcode-select --install"
        return 1
    fi
    print_success "stapler command found"
    print_verbose "stapler version: $(stapler --version 2>/dev/null || echo 'version unknown')"

    local verification_passed=true
    local found_files=false

    # Check for DMG files
    local dmg_files=$(find Build/ -name "*.dmg" -type f 2>/dev/null)
    print_verbose "Found DMG files: $dmg_files"

    if [ -n "$dmg_files" ]; then
        found_files=true
        print_info "Verifying DMG notarization with stapler validate..."
        for dmg_file in $dmg_files; do
            print_info "Checking DMG: $dmg_file"
            print_verbose "DMG file size: $(ls -lh "$dmg_file" | awk '{print $5}')"

            if stapler validate "$dmg_file" 2>/dev/null; then
                print_success "DMG notarization is valid: $dmg_file"
                print_verbose "Stapler validate output:"
                print_verbose "$(stapler validate "$dmg_file" 2>&1)"
            else
                print_error "DMG notarization is invalid or missing: $dmg_file"
                print_verbose "Stapler validate output:"
                print_verbose "$(stapler validate "$dmg_file" 2>&1)"
                verification_passed=false
            fi
        done
    else
        print_warning "No DMG files found in Build directory"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type f 2>/dev/null || echo 'No Build directory found')"
        print_info "Run ./Scripts/package.sh first to create DMG files"
        return 0
    fi

    if [ "$verification_passed" = true ]; then
        print_success "DMG notarization validation completed successfully!"
        return 0
    else
        print_error "DMG notarization validation failed!"
        return 1
    fi
}

# Function to verify PKG notarization using stapler validate
verify_notarize_pkg() {
    print_info "Verifying PKG notarization using stapler validate..."
    echo ""

    # Check if stapler command is available
    if ! command -v stapler &> /dev/null; then
        print_error "stapler command not found"
        print_info "stapler is part of Xcode Command Line Tools"
        print_info "Please install with: xcode-select --install"
        return 1
    fi
    print_success "stapler command found"
    print_verbose "stapler version: $(stapler --version 2>/dev/null || echo 'version unknown')"

    local verification_passed=true
    local found_files=false

    # Check for PKG files
    local pkg_files=$(find Build/ -name "*.pkg" -type f 2>/dev/null)
    print_verbose "Found PKG files: $pkg_files"

    if [ -n "$pkg_files" ]; then
        found_files=true
        print_info "Verifying PKG notarization with stapler validate..."
        for pkg_file in $pkg_files; do
            print_info "Checking PKG: $pkg_file"
            print_verbose "PKG file size: $(ls -lh "$pkg_file" | awk '{print $5}')"

            if stapler validate "$pkg_file" 2>/dev/null; then
                print_success "PKG notarization is valid: $pkg_file"
                print_verbose "Stapler validate output:"
                print_verbose "$(stapler validate "$pkg_file" 2>&1)"
            else
                print_error "PKG notarization is invalid or missing: $pkg_file"
                print_verbose "Stapler validate output:"
                print_verbose "$(stapler validate "$pkg_file" 2>&1)"
                verification_passed=false
            fi
        done
    else
        print_warning "No PKG files found in Build directory"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type f 2>/dev/null || echo 'No Build directory found')"
        print_info "Run ./Scripts/package.sh first to create PKG files"
        return 0
    fi

    if [ "$verification_passed" = true ]; then
            print_success "PKG notarization validation completed successfully!"
    return 0
else
    print_error "PKG notarization validation failed!"
    return 1
fi
}

# Function to verify app store requirements using altool
verify_app_store_requirements() {
    print_info "Verifying app meets App Store requirements using altool..."
    echo ""

    # Check if altool command is available
    if ! command -v xcrun &> /dev/null; then
        print_error "xcrun command not found"
        print_info "xcrun is part of Xcode Command Line Tools"
        print_info "Please install with: xcode-select --install"
        return 1
    fi
    print_success "xcrun command found"
    print_verbose "xcrun version: $(xcrun --version 2>/dev/null || echo 'version unknown')"

    # Check if app bundle exists
    if [ ! -d "Build/package/BongoCat.app" ]; then
        print_error "No app bundle found to verify"
        print_info "Run ./Scripts/package.sh first to create the app bundle"
        print_verbose "Build directory contents:"
        print_verbose "$(find Build/ -type d 2>/dev/null || echo 'No Build directory found')"
        return 1
    fi

    local app_path="Build/package/BongoCat.app"
    print_verbose "App path: $app_path"

    # Check if Apple ID credentials are set
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
        print_error "Apple ID credentials not set for App Store validation"
        print_info "Please set APPLE_ID and APPLE_ID_PASSWORD environment variables"
        print_verbose "APPLE_ID: ${APPLE_ID:-'not set'}"
        print_verbose "APPLE_ID_PASSWORD: ${APPLE_ID_PASSWORD:+'set'}"
        return 1
    fi
    print_success "Apple ID credentials found"
    print_verbose "Using Apple ID: $APPLE_ID"

    # Create a temporary zip file for validation
    local validation_zip="Build/BongoCat-validation.zip"
    print_info "Creating validation zip file..."

    # Remove existing validation zip if it exists
    if [ -f "$validation_zip" ]; then
        rm "$validation_zip"
        print_verbose "Removed existing validation zip: $validation_zip"
    fi

    # Create zip file
    if cd "Build/package" && zip -r "../BongoCat-validation.zip" "BongoCat.app" > /dev/null 2>&1; then
        print_success "Created validation zip file: $validation_zip"
        print_verbose "Validation zip size: $(ls -lh "$validation_zip" | awk '{print $5}')"
    else
        print_error "Failed to create validation zip file"
        print_verbose "Zip command output:"
        print_verbose "$(cd "Build/package" && zip -r "../BongoCat-validation.zip" "BongoCat.app" 2>&1)"
        cd "$PROJECT_ROOT"
        return 1
    fi

    cd "$PROJECT_ROOT"

    # Validate app using altool
    print_info "Validating app with altool..."
    print_verbose "Running: xcrun altool --validate-app -f \"$validation_zip\" -t macos -u \"$APPLE_ID\" -p \"$APPLE_ID_PASSWORD\""

    if xcrun altool --validate-app \
        -f "$validation_zip" \
        -t macos \
        -u "$APPLE_ID" \
        -p "$APPLE_ID_PASSWORD" 2>&1 | tee /tmp/altool_output.txt; then
        print_success "App Store validation passed!"
        print_verbose "Altool validation output:"
        print_verbose "$(cat /tmp/altool_output.txt)"
    else
        print_error "App Store validation failed!"
        print_verbose "Altool validation output:"
        print_verbose "$(cat /tmp/altool_output.txt)"

        # Clean up validation zip
        rm -f "$validation_zip"
        rm -f /tmp/altool_output.txt
        return 1
    fi

    # Clean up validation zip
    rm -f "$validation_zip"
    rm -f /tmp/altool_output.txt
    print_verbose "Cleaned up validation zip file"

    print_success "App Store requirements verification completed!"
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment|-e)
            VERIFY_ENVIRONMENT=true
            shift
            ;;
        --signature|-s)
            VERIFY_SIGNATURE=true
            shift
            ;;
        --signatures|-S)
            VERIFY_SIGNATURES=true
            shift
            ;;
        --notarization|-n)
            VERIFY_NOTARIZATION=true
            shift
            ;;
        --notarize-dmg|-A)
            VERIFY_NOTARIZE_APP=true
            shift
            ;;
        --notarize-pkg|-P)
            VERIFY_NOTARIZE_PKG=true
            shift
            ;;
        --build|-b)
            VERIFY_BUILD=true
            shift
            ;;
        --versions|-v)
            VERIFY_VERSIONS=true
            shift
            ;;
        --app-store-requirements)
            VERIFY_APP_STORE_REQUIREMENTS=true
            shift
            ;;
        --all|-a)
            VERIFY_ALL=true
            shift
            ;;
        --verbose|-V)
            VERBOSE=true
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

# If no specific verification is requested, show help
if [ "$VERIFY_ENVIRONMENT" = false ] && [ "$VERIFY_SIGNATURE" = false ] && [ "$VERIFY_SIGNATURES" = false ] && [ "$VERIFY_NOTARIZATION" = false ] && [ "$VERIFY_NOTARIZE_APP" = false ] && [ "$VERIFY_NOTARIZE_PKG" = false ] && [ "$VERIFY_BUILD" = false ] && [ "$VERIFY_VERSIONS" = false ] && [ "$VERIFY_APP_STORE_REQUIREMENTS" = false ] && [ "$VERIFY_ALL" = false ]; then
    show_usage
    exit 0
fi

# Main execution
echo "🔍 BongoCat Verify Script"
echo "========================"
if [ "$VERBOSE" = true ]; then
    echo "🔍 Verbose mode enabled"
fi
echo ""

# Run requested verifications
if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_ENVIRONMENT" = true ]; then
    verify_environment
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_SIGNATURE" = true ]; then
    verify_signature
    echo ""
fi

if [ "$VERIFY_SIGNATURES" = true ]; then
    verify_signatures
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_NOTARIZATION" = true ]; then
    verify_notarization
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_NOTARIZE_APP" = true ]; then
    verify_notarize_app
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_NOTARIZE_PKG" = true ]; then
    verify_notarize_pkg
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_BUILD" = true ]; then
    verify_build
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_VERSIONS" = true ]; then
    verify_versions
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_APP_STORE_REQUIREMENTS" = true ]; then
    verify_app_store_requirements
    echo ""
fi

echo ""
print_success "Verification completed successfully!"