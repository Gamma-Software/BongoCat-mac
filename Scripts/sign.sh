#!/bin/bash

# BongoCat Sign Script - Code signing and notarization
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

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Default values
SIGN_APP=false
SIGN_PKG=false
NOTARIZE_APP=false
SIGN_MODE="auto"
FORCE_SIGN=false

# Function to show usage
show_usage() {
    echo "🔐 BongoCat Sign Script"
    echo "======================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Signing Options:"
    echo "  --app, -a              Sign the app bundle"
    echo "  --pkg, -p              Sign the PKG installer"
    echo "  --notarize, -n         Notarize the app"
    echo "  --all, -A              Sign app, PKG and notarize"
    echo ""
    echo "Signing Mode:"
    echo "  --adhoc, -d            Force ad-hoc signing (no certificate)"
    echo "  --certificate, -c      Force certificate signing"
    echo "  --auto, -u             Auto-detect certificate (default)"
    echo "  --force, -f            Force re-signing even if already signed"
    echo ""
    echo "Examples:"
    echo "  $0 --app"
    echo "  $0 --app --notarize"
    echo "  $0 --all"
    echo "  $0 --app --adhoc"
    echo ""
    echo "🔐 Code Signing:"
    echo "  • Auto: Detects available certificates"
    echo "  • Ad-hoc: No certificate required, for development"
    echo "  • Certificate: Requires Apple Developer certificate"
    echo ""
    echo "📋 Notarization:"
    echo "  • Requires Apple ID credentials"
    echo "  • Set APPLE_ID and APPLE_ID_PASSWORD environment variables"
    echo "  • Use app-specific password if 2FA is enabled"
    echo ""
    echo "🍎 App Store:"
    echo "  • Requires Apple Developer Program membership"
    echo "  • Requires App Store provisioning profile"
    echo "  • App will be signed with App Store distribution certificate"
}

# Function to check if Apple Developer certificate is available
check_developer_certificate() {
    # Check for Developer ID certificate
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        print_success "Found Developer ID certificate"
        return 0
    fi

    # Check for Mac App Distribution certificate
    if security find-identity -v -p codesigning | grep -q "Mac App Distribution"; then
        print_success "Found Mac App Distribution certificate"
        return 0
    fi

    # Check for Apple Development certificate
    if security find-identity -v -p codesigning | grep -q "Apple Development"; then
        print_warning "Found Apple Development certificate (for development only)"
        return 0
    fi

    # Check for Mac Developer certificate
    if security find-identity -v -p codesigning | grep -q "Mac Developer"; then
        print_warning "Found Mac Developer certificate (for development only)"
        return 0
    fi

    print_error "No Apple Developer certificate found"
    return 1
}

# Function to get certificate identity
get_certificate_identity() {
    local identity=""

    # Try Developer ID first (for distribution)
    identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | awk '{print $2}')
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    # Try Mac App Distribution
    identity=$(security find-identity -v -p codesigning | grep "Mac App Distribution" | awk '{print $2}')
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    # Try Apple Development (development only)
    identity=$(security find-identity -v -p codesigning | grep "Apple Development" | awk '{print $2}')
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    # Try Mac Developer (development only)
    identity=$(security find-identity -v -p codesigning | grep "Mac Developer" | awk '{print $2}')
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    return 1
}

# Function to sign the app bundle
sign_app() {
    print_info "Signing app bundle..."

    local app_path="Build/package/BongoCat.app"

    # Check if app bundle exists
    if [ ! -d "$app_path" ]; then
        print_error "App bundle not found: $app_path"
        print_info "Run ./Scripts/package.sh first"
        return 1
    fi

    # Check if already signed
    if codesign -dv "$app_path" 2>&1 | grep -q "signed" && [ "$FORCE_SIGN" = false ]; then
        print_warning "App is already signed"
        print_info "Use --force to re-sign"
        return 0
    fi

    # Determine signing method
    local sign_identity=""
    if [ "$SIGN_MODE" = "adhoc" ]; then
        print_info "Using ad-hoc signing..."
        sign_identity="-"
    elif [ "$SIGN_MODE" = "certificate" ]; then
        if ! check_developer_certificate; then
            print_error "No certificate found for certificate signing"
            return 1
        fi
        sign_identity=$(get_certificate_identity)
        print_info "Using certificate signing: $sign_identity"
    else
        # Auto mode
        if check_developer_certificate; then
            sign_identity=$(get_certificate_identity)
            print_info "Using certificate signing: $sign_identity"
        else
            print_info "No certificate found, using ad-hoc signing..."
            sign_identity="-"
        fi
    fi

    # Sign the app
    print_info "Signing app bundle with identity: $sign_identity"
    if codesign --force --sign "$sign_identity" --timestamp --options runtime "$app_path"; then
        print_success "App bundle signed successfully!"

        # Verify signature
        if codesign -v "$app_path" 2>/dev/null; then
            print_success "App signature verified successfully!"
        else
            print_error "App signature verification failed!"
            return 1
        fi
    else
        print_error "Failed to sign app bundle"
        return 1
    fi
}

# Function to sign the PKG installer
sign_pkg() {
    print_info "Signing PKG installer..."

    # Find PKG file
    local pkg_file=$(find Build/ -name "*.pkg" -type f | head -1)

    if [ -z "$pkg_file" ]; then
        print_error "No PKG file found in Build directory"
        print_info "Run ./Scripts/package.sh first"
        return 1
    fi

    print_info "Found PKG file: $pkg_file"

    # Check if already signed
    if pkgutil --check-signature "$pkg_file" 2>/dev/null | grep -q "signed" && [ "$FORCE_SIGN" = false ]; then
        print_warning "PKG is already signed"
        print_info "Use --force to re-sign"
        return 0
    fi

    # Determine signing method
    local sign_identity=""
    if [ "$SIGN_MODE" = "adhoc" ]; then
        print_info "Using ad-hoc signing..."
        sign_identity="-"
    elif [ "$SIGN_MODE" = "certificate" ]; then
        if ! check_developer_certificate; then
            print_error "No certificate found for certificate signing"
            return 1
        fi
        sign_identity=$(get_certificate_identity)
        print_info "Using certificate signing: $sign_identity"
    else
        # Auto mode
        if check_developer_certificate; then
            sign_identity=$(get_certificate_identity)
            print_info "Using certificate signing: $sign_identity"
        else
            print_info "No certificate found, using ad-hoc signing..."
            sign_identity="-"
        fi
    fi

    # Sign the PKG
    print_info "Signing PKG with identity: $sign_identity"
    if productsign --sign "$sign_identity" --timestamp "$pkg_file" "${pkg_file}.signed"; then
        mv "${pkg_file}.signed" "$pkg_file"
        print_success "PKG signed successfully!"

        # Verify signature
        if pkgutil --check-signature "$pkg_file" 2>/dev/null; then
            print_success "PKG signature verified successfully!"
        else
            print_error "PKG signature verification failed!"
            return 1
        fi
    else
        print_error "Failed to sign PKG"
        return 1
    fi
}

# Function to notarize the app
notarize_app() {
    print_info "Notarizing app..."

    # Check Apple ID credentials
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
        print_error "Apple ID credentials not set"
        echo ""
        echo "💡 Set environment variables:"
        echo "   export APPLE_ID='your-apple-id@example.com'"
        echo "   export APPLE_ID_PASSWORD='your-app-specific-password'"
        echo "   export TEAM_ID='your-team-id'"
        echo ""
        echo "📝 Note: Use an app-specific password if you have 2FA enabled"
        return 1
    fi

    local app_path="Build/package/BongoCat.app"

    # Check if app bundle exists
    if [ ! -d "$app_path" ]; then
        print_error "App bundle not found: $app_path"
        print_info "Run ./Scripts/package.sh first"
        return 1
    fi

    # Check if app is signed
    if ! codesign -dv "$app_path" 2>&1 | grep -q "signed"; then
        print_error "App must be signed before notarization"
        print_info "Run: $0 --app first"
        return 1
    fi

    # Create DMG for notarization if it doesn't exist
    local dmg_file="Build/BongoCat-$(defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0").dmg"

    if [ ! -f "$dmg_file" ]; then
        print_info "Creating DMG for notarization..."
        if ! ./Scripts/package.sh --dmg-only; then
            print_error "Failed to create DMG for notarization"
            return 1
        fi
    fi

    print_info "Submitting app for notarization..."

    # Submit for notarization
    local submission_id=""
    if command -v xcrun &> /dev/null; then
        # Use notarytool (macOS 12.3+)
        print_info "Using notarytool for submission..."
        submission_id=$(xcrun notarytool submit "$dmg_file" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" --wait 2>/dev/null | grep "id:" | awk '{print $2}')
    else
        # Fallback to altool
        print_info "Using altool for submission..."
        submission_id=$(xcrun altool --notarize-app --primary-bundle-id "com.leaptech.bongocat" --username "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --file "$dmg_file" 2>/dev/null | grep "RequestUUID" | awk '{print $3}')
    fi

    if [ -n "$submission_id" ]; then
        print_success "Notarization submitted successfully!"
        print_info "Submission ID: $submission_id"

        # Wait for notarization to complete
        print_info "Waiting for notarization to complete..."
        sleep 30

        # Check notarization status
        if command -v xcrun &> /dev/null; then
            if xcrun notarytool info "$submission_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" 2>/dev/null | grep -q "status: accepted"; then
                print_success "Notarization completed successfully!"

                # Staple the ticket
                print_info "Stapling notarization ticket..."
                if xcrun stapler staple "$dmg_file"; then
                    print_success "Notarization ticket stapled successfully!"
                else
                    print_warning "Failed to staple notarization ticket"
                fi
            else
                print_error "Notarization failed or is still in progress"
                return 1
            fi
        else
            print_warning "Cannot check notarization status with altool"
            print_info "Check manually in App Store Connect"
        fi
    else
        print_error "Failed to submit for notarization"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --app|-a)
            SIGN_APP=true
            shift
            ;;
        --pkg|-p)
            SIGN_PKG=true
            shift
            ;;
        --notarize|-n)
            NOTARIZE_APP=true
            shift
            ;;
        --all|-A)
            SIGN_APP=true
            SIGN_PKG=true
            NOTARIZE_APP=true
            shift
            ;;
        --adhoc|-d)
            SIGN_MODE="adhoc"
            shift
            ;;
        --certificate|-c)
            SIGN_MODE="certificate"
            shift
            ;;
        --auto|-u)
            SIGN_MODE="auto"
            shift
            ;;
        --force|-f)
            FORCE_SIGN=true
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

# If no specific action is requested, sign app by default
if [ "$SIGN_APP" = false ] && [ "$SIGN_PKG" = false ] && [ "$NOTARIZE_APP" = false ]; then
    SIGN_APP=true
fi

# Main execution
echo "🔐 BongoCat Sign Script"
echo "======================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Sign app if requested
if [ "$SIGN_APP" = true ]; then
    sign_app
    echo ""
fi

# Sign PKG if requested
if [ "$SIGN_PKG" = true ]; then
    sign_pkg
    echo ""
fi

# Notarize app if requested
if [ "$NOTARIZE_APP" = true ]; then
    notarize_app
    echo ""
fi

echo ""
print_success "Signing completed successfully!"