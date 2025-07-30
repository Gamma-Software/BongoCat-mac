#!/bin/bash

# BangoCat Code Signing Script
set -xe

source .env

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

APP_NAME="BangoCat"
BUNDLE_ID="com.leaptech.bangocat"
APP_BUNDLE="Build/package/${APP_NAME}.app"

# Function to check if Apple Developer certificate is available
check_developer_certificate() {
    echo "🔍 Checking for Apple Developer certificate..."

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
    identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d'"' -f2)
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    # Try Mac App Distribution
    identity=$(security find-identity -v -p codesigning | grep "Mac App Distribution" | head -1 | cut -d'"' -f2)
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    # Try Apple Development (development only)
    identity=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | cut -d'"' -f2)
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    # Try Mac Developer (development only)
    identity=$(security find-identity -v -p codesigning | grep "Mac Developer" | head -1 | cut -d'"' -f2)
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi

    return 1
}

# Function to notarize the app
notarize_app() {
    local dmg_file="$1"
    local app_path="$2"

    echo "📤 Starting notarization process..."

    # Check if we have notarytool available
    if ! xcrun notarytool --version &> /dev/null; then
        print_error "notarytool not available. Install Xcode command line tools:"
        echo "   xcode-select --install"
        return 1
    fi

    # Create a temporary zip for notarization
    local temp_zip="/tmp/${APP_NAME}-notarize.zip"
    echo "📦 Creating temporary zip for notarization..."
    ditto -c -k --keepParent "$app_path" "$temp_zip"

    echo "📤 Uploading for notarization..."
    print_info "Using notarytool for modern notarization"

    # Upload for notarization using notarytool
    local upload_output

    # Check if TEAM_ID is set, if not try to get it automatically
    if [ -z "$TEAM_ID" ]; then
        echo "🔍 Getting team ID automatically..."
        local team_info
        team_info=$(xcrun notarytool info --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" 2>/dev/null)
        if echo "$team_info" | grep -q "team_id:"; then
            TEAM_ID=$(echo "$team_info" | grep "team_id:" | awk '{print $2}')
            echo "📋 Found Team ID: $TEAM_ID"
        else
            print_error "Could not automatically determine Team ID"
            echo "💡 Please set your Team ID:"
            echo "   export TEAM_ID='your-team-id'"
            echo "   You can find it at: https://developer.apple.com/account/#!/membership"
            return 1
        fi
    fi

    upload_output=$(xcrun notarytool submit "$temp_zip" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --team-id "$TEAM_ID" 2>&1)

    if echo "$upload_output" | grep -q "id:"; then
        local submission_id=$(echo "$upload_output" | grep -m1 "id:" | awk '{print $2}')
        print_success "Upload successful! Submission ID: $submission_id"

        echo "⏳ Waiting for notarization to complete..."
        echo "   This can take 5-15 minutes..."

        # Wait for notarization to complete
        while true; do
            #sleep 30
            local status_output
            status_output=$(xcrun notarytool wait "$submission_id" \
                --apple-id "$APPLE_ID" \
                --password "$APPLE_ID_PASSWORD" \
                --team-id "$TEAM_ID" 2>&1)

            if echo "$status_output" | grep -q "status: Accepted"; then
                print_success "Notarization completed successfully!"
                break
            elif echo "$status_output" | grep -q "status: Invalid"; then
                print_error "Notarization failed!"
                log_output=$(xcrun notarytool log "$submission_id" \
                    --apple-id "$APPLE_ID" \
                    --password "$APPLE_ID_PASSWORD" \
                    --team-id "$TEAM_ID" 2>&1)
                echo "$log_output"
                return 1
            else
                echo "⏳ Still processing... (checking again in 30 seconds)"
            fi
        done

        # Staple the notarization ticket to the app
        echo "📎 Stapling notarization ticket to app..."
        xcrun stapler staple "$app_path"
        print_success "Notarization ticket stapled successfully!"

    else
        print_error "Upload failed:"
        echo "$upload_output"
        return 1
    fi

    # Clean up
    rm -f "$temp_zip"
}

# Function to sign with ad-hoc signature (no certificate required)
sign_adhoc() {
    echo "🔐 Signing with ad-hoc signature..."

    if codesign --force --deep --sign - "$APP_BUNDLE"; then
        print_success "App signed with ad-hoc signature"
        print_warning "This will still trigger Gatekeeper warnings"
        print_info "Users will need to right-click and select 'Open'"
        return 0
    else
        print_error "Ad-hoc signing failed"
        return 1
    fi
}

# Function to sign with Apple Developer certificate
sign_with_certificate() {
    local identity="$1"

    echo "🔐 Signing with Apple Developer certificate..."
    echo "📋 Certificate: $identity"

    # Sign the app bundle with hardened runtime and timestamp for notarization
    if codesign --force --deep --sign "$identity" \
        --options runtime \
        --timestamp \
        "$APP_BUNDLE"; then
        print_success "App signed with Apple Developer certificate"
        print_info "Hardened runtime enabled"
        print_info "Secure timestamp included"

        # Verify the signature
        echo "🔍 Verifying signature..."
        if codesign --verify --verbose "$APP_BUNDLE"; then
            print_success "Signature verification passed"
            return 0
        else
            print_error "Signature verification failed"
            return 1
        fi
    else
        print_error "Code signing failed"
        return 1
    fi
}

# Main execution
echo "🔐 BangoCat Code Signing Script"
echo "================================"

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    print_error "App bundle not found: $APP_BUNDLE"
    echo ""
    echo "💡 Build the app first:"
    echo "   ./Scripts/build.sh"
    echo "   ./Scripts/package_app.sh"
    exit 1
fi

# Parse command line arguments
SIGN_MODE="auto"
NOTARIZE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --adhoc)
            SIGN_MODE="adhoc"
            shift
            ;;
        --certificate)
            SIGN_MODE="certificate"
            shift
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--adhoc] [--certificate] [--notarize] [--help]"
            echo "  --adhoc       Sign with ad-hoc signature (no certificate required)"
            echo "  --certificate Sign with Apple Developer certificate"
            echo "  --notarize    Notarize the app with Apple (requires certificate)"
            echo "  --help        Show this help message"
            echo ""
            echo "Default behavior:"
            echo "  - Try to use Apple Developer certificate if available"
            echo "  - Fall back to ad-hoc signing if no certificate found"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check signing mode and execute
case $SIGN_MODE in
    "adhoc")
        sign_adhoc
        ;;
    "certificate")
        if check_developer_certificate; then
            identity=$(get_certificate_identity)
            if [ -n "$identity" ]; then
                sign_with_certificate "$identity"
            else
                print_error "Failed to get certificate identity"
                exit 1
            fi
        else
            print_error "No Apple Developer certificate available"
            exit 1
        fi
        ;;
    "auto")
        if check_developer_certificate; then
            identity=$(get_certificate_identity)
            if [ -n "$identity" ]; then
                sign_with_certificate "$identity"
            else
                print_error "Failed to get certificate identity"
                exit 1
            fi
        else
            print_warning "No Apple Developer certificate found, using ad-hoc signing"
            sign_adhoc
        fi
        ;;
esac

# Handle notarization if requested
if [ "$NOTARIZE" = true ]; then
    if [ "$SIGN_MODE" = "adhoc" ]; then
        print_error "Notarization requires Apple Developer certificate"
        exit 1
    fi

    # Check for Apple ID credentials
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
        print_error "Apple ID credentials required for notarization"
        echo ""
        echo "💡 Set environment variables:"
        echo "   export APPLE_ID='your-apple-id@example.com'"
        echo "   export APPLE_ID_PASSWORD='your-app-specific-password'"
        echo ""
        echo "📝 Note: Use an app-specific password if you have 2FA enabled"
        exit 1
    fi

    notarize_app "" "$APP_BUNDLE"
fi

echo ""
echo "🎉 Code signing completed!"
echo ""
echo "📋 Next steps:"
if [ "$SIGN_MODE" = "adhoc" ]; then
    echo "   • Users will need to right-click and select 'Open' on first launch"
    echo "   • Consider getting an Apple Developer certificate for better distribution"
else
    echo "   • App should launch without Gatekeeper warnings"
    if [ "$NOTARIZE" = true ]; then
        echo "   • App is notarized and ready for distribution"
    else
        echo "   • Consider notarizing for complete distribution readiness"
    fi
fi