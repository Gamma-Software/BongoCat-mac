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

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Default values
VERIFY_ENVIRONMENT=false
VERIFY_SIGNATURE=false
VERIFY_SIGNATURES=false
VERIFY_NOTARIZATION=false
VERIFY_BUILD=false
VERIFY_VERSIONS=false
VERIFY_ALL=false

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
    echo "  --build, -b           Verify build artifacts and dependencies"
    echo "  --versions, -v        Verify version consistency across project"
    echo "  --all, -a             Run all verification checks"
    echo ""
    echo "Examples:"
    echo "  $0 --environment"
    echo "  $0 --signature"
    echo "  $0 --all"
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

    # Check if Xcode Command Line Tools are installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode Command Line Tools not found"
        echo "   Please install with: xcode-select --install"
        return 1
    fi
    print_success "Xcode Command Line Tools found"

    # Check Swift version
    if ! command -v swift &> /dev/null; then
        print_error "Swift not found"
        return 1
    fi
    local swift_version=$(swift --version | head -n 1)
    print_success "Swift found: $swift_version"

    # Check if we're in the right directory
    if [ ! -f "Package.swift" ]; then
        print_error "Package.swift not found. Please run this script from the BongoCat-mac directory"
        return 1
    fi
    print_success "Package.swift found"

    # Check if required scripts exist
    required_scripts=("Scripts/build.sh" "Scripts/package.sh" "Scripts/sign.sh")
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            print_error "Required script not found: $script"
            return 1
        fi
    done
    print_success "All required scripts found"

    # Check if source files exist
    if [ ! -f "Sources/BongoCat/main.swift" ]; then
        print_error "Main source file not found: Sources/BongoCat/main.swift"
        return 1
    fi
    print_success "Main source file found"

    # Check if cat images exist
    if [ ! -f "Sources/BongoCat/Resources/Images/base.png" ]; then
        print_error "Cat image resources not found"
        return 1
    fi
    print_success "Cat image resources found"

    # Check if Info.plist exists
    if [ ! -f "Info.plist" ]; then
        print_error "Info.plist not found"
        return 1
    fi
    print_success "Info.plist found"

    # Try to resolve dependencies
    print_info "Resolving Swift Package dependencies..."
    if swift package resolve; then
        print_success "Dependencies resolved successfully"
    else
        print_error "Failed to resolve dependencies"
        return 1
    fi

    # Check if we can build the project
    print_info "Testing build process..."
    if swift build --configuration debug; then
        print_success "Debug build successful"
    else
        print_error "Debug build failed"
        return 1
    fi

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

        if codesign -dv "$app_path" 2>&1 | grep -q "signed"; then
            print_success "App bundle is signed"

            # Check signature validity
            if codesign -v "$app_path" 2>/dev/null; then
                print_success "App signature is valid"
            else
                print_error "App signature is invalid"
                return 1
            fi
        else
            print_warning "App bundle is not signed"
        fi
    else
        print_info "No app bundle found to verify signature"
    fi

    # Check environment variables for notarization
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

        if codesign -dv "$app_path" 2>&1 | grep -q "signed"; then
            print_success "App bundle is signed"

            # Check signature validity
            if codesign -v "$app_path" 2>/dev/null; then
                print_success "App signature is valid"

                # Check signature details
                print_info "App signature details:"
                codesign -dv "$app_path" 2>&1 | grep -E "(Authority|Team|Timestamp)" || true
            else
                print_error "App signature is invalid"
                verification_passed=false
            fi
        else
            print_warning "App bundle is not signed"
        fi
    else
        print_info "No app bundle found to verify signature"
    fi

    # Verify PKG signature
    local pkg_files=$(find Build/ -name "*.pkg" -type f 2>/dev/null)
    if [ -n "$pkg_files" ]; then
        print_info "Verifying PKG signatures..."
        for pkg_file in $pkg_files; do
            print_info "Checking PKG: $pkg_file"
            if pkgutil --check-signature "$pkg_file" 2>/dev/null; then
                print_success "PKG signature is valid: $pkg_file"
            else
                print_error "PKG signature is invalid: $pkg_file"
                verification_passed=false
            fi
        done
    else
        print_info "No PKG files found to verify"
    fi

    # Verify DMG signature
    local dmg_files=$(find Build/ -name "*.dmg" -type f 2>/dev/null)
    if [ -n "$dmg_files" ]; then
        print_info "Verifying DMG signatures..."
        for dmg_file in $dmg_files; do
            print_info "Checking DMG: $dmg_file"
            if codesign -v "$dmg_file" 2>/dev/null; then
                print_success "DMG signature is valid: $dmg_file"
            else
                print_warning "DMG signature is invalid or missing: $dmg_file"
                # DMG files don't always need to be signed
            fi
        done
    else
        print_info "No DMG files found to verify"
    fi

    # Check notarization status
    if [ -d "Build/package/BongoCat.app" ]; then
        local app_path="Build/package/BongoCat.app"
        print_info "Checking notarization status..."

        if codesign -dv "$app_path" 2>&1 | grep -q "notarized"; then
            print_success "App is notarized"
        else
            print_warning "App is not notarized"
            print_info "Notarization is required for distribution outside App Store"
        fi
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
        return 0
    fi

    local app_path="Build/package/BongoCat.app"

    # Check if app is notarized
    print_info "Checking notarization status..."
    if codesign -dv "$app_path" 2>&1 | grep -q "notarized"; then
        print_success "App is notarized"
    else
        print_warning "App is not notarized"
        print_info "Notarization is required for distribution outside App Store"
    fi

    # Check if we can verify notarization with Apple
    if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ]; then
        print_info "Checking notarization ticket with Apple..."

        # Get the app's identifier
        local bundle_id=$(defaults read "$app_path/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.leaptech.bongocat")

        # Try to check notarization status
        if command -v xcrun &> /dev/null; then
            if xcrun notarytool info "$bundle_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" 2>/dev/null; then
                print_success "Notarization ticket found and valid"
            else
                print_warning "No notarization ticket found or invalid credentials"
            fi
        else
            print_warning "xcrun notarytool not available"
        fi
    else
        print_warning "Apple ID credentials not set for notarization verification"
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
        return 0
    fi

    # Check for debug build
    if [ -f ".build/debug/BongoCat" ]; then
        print_success "Debug binary found"
    fi

    # Check for release build
    if [ -f ".build/release/BongoCat" ]; then
        print_success "Release binary found"

        # Check if it's a universal binary
        local archs=$(lipo -info ".build/release/BongoCat" 2>/dev/null | grep -o "x86_64\|arm64" | wc -l)
        if [ "$archs" -eq 2 ]; then
            print_success "Universal binary (Intel + Apple Silicon)"
        else
            print_warning "Single architecture binary"
        fi
    fi

    # Check if Build directory exists
    if [ -d "Build" ]; then
        print_success "Build artifacts directory found"

        # Check for app bundle
        if [ -d "Build/package/BongoCat.app" ]; then
            print_success "App bundle found"

            # Check app bundle structure
            if [ -f "Build/package/BongoCat.app/Contents/Info.plist" ]; then
                print_success "App bundle structure is valid"
            else
                print_error "App bundle structure is invalid"
                return 1
            fi
        fi

        # Check for DMG
        if ls Build/*.dmg 1> /dev/null 2>&1; then
            print_success "DMG file found"
        fi

        # Check for PKG
        if ls Build/*.pkg 1> /dev/null 2>&1; then
            print_success "PKG file found"
        fi
    else
        print_info "No Build directory found"
        print_info "Run ./Scripts/package.sh first"
    fi

    # Check package dependencies
    print_info "Verifying package dependencies..."
    if swift package show-dependencies > /dev/null 2>&1; then
        print_success "Package dependencies are valid"
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
        return 1
    fi

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
        local short_version=$(defaults read Info.plist CFBundleShortVersionString 2>/dev/null || echo "unknown")
        local build_version=$(defaults read Info.plist CFBundleVersion 2>/dev/null || echo "unknown")
        print_info "  • Info.plist CFBundleShortVersionString: $short_version"
        print_info "  • Info.plist CFBundleVersion: $build_version"
    fi

    print_success "Version verification completed!"
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
        --build|-b)
            VERIFY_BUILD=true
            shift
            ;;
        --versions|-v)
            VERIFY_VERSIONS=true
            shift
            ;;
        --all|-a)
            VERIFY_ALL=true
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

# If no specific verification is requested, run all
if [ "$VERIFY_ENVIRONMENT" = false ] && [ "$VERIFY_SIGNATURE" = false ] && [ "$VERIFY_SIGNATURES" = false ] && [ "$VERIFY_NOTARIZATION" = false ] && [ "$VERIFY_BUILD" = false ] && [ "$VERIFY_VERSIONS" = false ] && [ "$VERIFY_ALL" = false ]; then
    VERIFY_ALL=true
fi

# Main execution
echo "🔍 BongoCat Verify Script"
echo "========================"
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

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_SIGNATURES" = true ]; then
    verify_signatures
    echo ""
fi

if [ "$VERIFY_ALL" = true ] || [ "$VERIFY_NOTARIZATION" = true ]; then
    verify_notarization
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

echo ""
print_success "Verification completed successfully!"