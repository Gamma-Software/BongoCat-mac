#!/bin/bash

# BongoCat Sign Script - Code signing and notarization
set -xe

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
SIGN_DMG=false
SIGN_PKG=false
NOTARIZE_APP=false
NOTARIZE_DMG=false
NOTARIZE_PKG=false
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
    echo "  --app, -a              Sign the app bundle (.app)"
    echo "  --dmg, -d              Sign the DMG disk image (.dmg)"
    echo "  --pkg, -p              Sign the PKG installer (.pkg)"
    echo "  --notarize, -n         Notarize all files (DMG and PKG)"
    echo "  --notarize-dmg         Notarize only DMG files"
    echo "  --notarize-pkg         Notarize only PKG files"
    echo "  --all, -A              Sign app, DMG, PKG and notarize"
    echo ""
    echo "Signing Mode:"
    echo "  --adhoc, -h            Force ad-hoc signing (no certificate)"
    echo "  --certificate, -c      Force certificate signing"
    echo "  --auto, -u             Auto-detect certificate (default)"
    echo "  --force, -f            Force re-signing even if already signed"
    echo ""
    echo "Examples:"
    echo "  $0 --app"
    echo "  $0 --app --dmg --pkg"
    echo "  $0 --all"
    echo "  $0 --app --adhoc"
    echo "  $0 --notarize-dmg"
    echo "  $0 --notarize-pkg"
    echo "  $0 --dmg --notarize-dmg"
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

# Check for Mac Distribution certificate
check_mac_distribution_certificate() {
    # Check for Developer ID certificate
    if security find-identity -v | grep -q "3rd Party Mac Developer Installer"; then
        print_success "Found Mac Distribution certificate"
        return 0
    fi
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
get_pkg_signing_certificate_identity() {
    local identity=""
    identity=$(security find-identity -v | grep "3rd Party Mac Developer Installer" | awk '{print $2}')
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi
}

# Function to get Developer ID certificate for notarization
get_developer_id_certificate() {
    local identity=""
    identity=$(security find-identity -v -p codesigning | grep "Developer ID Application" | awk '{print $2}')
    if [ -n "$identity" ]; then
        echo "$identity"
        return 0
    fi
    return 1
}

get_code_signing_certificate_identity() {
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
    current_sign=$(codesign -dv "$app_path" 2>&1)
    if echo "$current_sign" | grep -q "TeamIdentifier=$TEAM_ID" && [ "$FORCE_SIGN" = false ]; then
        print_warning "App is already signed"
        print_info "Current signature: $current_sign"
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
        sign_identity=$(get_code_signing_certificate_identity)
        print_info "Using certificate signing: $sign_identity"
    else
        # Auto mode - prefer Developer ID for notarization
        if get_developer_id_certificate > /dev/null; then
            sign_identity=$(get_developer_id_certificate)
            print_info "Using Developer ID certificate for notarization: $sign_identity"
        elif check_developer_certificate; then
            sign_identity=$(get_code_signing_certificate_identity)
            print_info "Using certificate signing: $sign_identity"
        else
            print_info "No certificate found, using ad-hoc signing..."
            sign_identity="-"
        fi
    fi

    # Sign the app with hardened runtime and secure timestamp
    print_info "Signing app bundle with identity: $sign_identity"
    print_info "Using entitlements: $PROJECT_ROOT/BongoCat.entitlements"
    if codesign --force --deep --sign "$sign_identity" --timestamp --options runtime --entitlements "$PROJECT_ROOT/BongoCat.entitlements" "$app_path"; then
        print_success "App bundle signed successfully!"

        # Verify signature
        if codesign -v "$app_path" 2>/dev/null; then
            print_success "App signature verified successfully!"

            # Show detailed signature information
            print_info "Signature details:"
            codesign -dv "$app_path" 2>&1 | grep -E "(Authority|Team|Timestamp|Runtime)" || true
        else
            print_error "App signature verification failed!"
            return 1
        fi
    else
        print_error "Failed to sign app bundle"
        return 1
    fi
}

# Function to sign the DMG disk image
sign_dmg() {
    print_info "Signing DMG disk image..."

    # Find DMG file
    local dmg_file=$(find Build/ -name "*.dmg" -type f | head -1)

    if [ -z "$dmg_file" ]; then
        print_error "No DMG file found in Build directory"
        print_info "Run ./Scripts/package.sh --dmg first"
        return 1
    fi

    print_info "Found DMG file: $dmg_file"

    # Check if already signed
    current_dmg_sign=$(codesign -dv "$dmg_file" 2>&1 || true)
    if echo "$current_dmg_sign" | grep -q "TeamIdentifier=$TEAM_ID" && [ "$FORCE_SIGN" = false ]; then
        print_warning "DMG is already signed"
        print_info "Current signature: $current_dmg_sign"
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
        sign_identity=$(get_code_signing_certificate_identity)
        print_info "Using certificate signing: $sign_identity"
    else
        # Auto mode - prefer Developer ID for notarization
        if get_developer_id_certificate > /dev/null; then
            sign_identity=$(get_developer_id_certificate)
            print_info "Using Developer ID certificate for notarization: $sign_identity"
        elif check_developer_certificate; then
            sign_identity=$(get_code_signing_certificate_identity)
            print_info "Using certificate signing: $sign_identity"
        else
            print_info "No certificate found, using ad-hoc signing..."
            sign_identity="-"
        fi
    fi

    # Sign the DMG with secure timestamp
    print_info "Signing DMG with identity: $sign_identity"
    if codesign --force --sign "$sign_identity" --timestamp "$dmg_file"; then
        print_success "DMG signed successfully!"

        # Verify signature
        if codesign -v "$dmg_file" 2>/dev/null; then
            print_success "DMG signature verified successfully!"
        else
            print_error "DMG signature verification failed!"
            return 1
        fi
    else
        print_error "Failed to sign DMG"
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
        print_info "Run ./Scripts/package.sh --pkg first"
        return 1
    fi

    print_info "Found PKG file: $pkg_file"

    # Check if already signed
    if pkgutil --check-signature "$pkg_file" 2>/dev/null | grep -q "signed" && [ "$FORCE_SIGN" = false ]; then
        print_warning "PKG is already signed"
        print_info "Current signature details:"
        pkgutil --check-signature "$pkg_file"
        print_info "Use --force to re-sign"
        return 0
    fi

    # Determine signing method
    local sign_identity=""
    if [ "$SIGN_MODE" = "adhoc" ]; then
        print_info "Using ad-hoc signing..."
        sign_identity="-"
    elif [ "$SIGN_MODE" = "certificate" ]; then
        if ! check_mac_distribution_certificate; then
            print_error "No certificate found for certificate signing"
            return 1
        fi
        sign_identity=$(get_pkg_signing_certificate_identity)
        print_info "Using certificate signing: $sign_identity"
    else
        # Auto mode
        if check_mac_distribution_certificate; then
            sign_identity=$(get_pkg_signing_certificate_identity)
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

# Function to notarize DMG and PKG files
notarize_app() {
    print_info "Notarizing DMG and PKG files..."

    # Check if we have notarytool available
    if ! xcrun notarytool --version &> /dev/null; then
        print_error "notarytool not available. Install Xcode command line tools:"
        echo "   xcode-select --install"
        return 1
    fi

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

    # Check for Developer ID certificate (required for notarization)
    if ! get_developer_id_certificate > /dev/null; then
        print_error "No Developer ID certificate found"
        echo ""
        echo "💡 You need a Developer ID certificate for notarization:"
        echo "   1. Join Apple Developer Program"
        echo "   2. Create a Developer ID certificate in Xcode"
        echo "   3. Download and install the certificate"
        echo ""
        echo "🔍 Available certificates:"
        security find-identity -v -p codesigning | grep -E "(Developer ID|Mac App Distribution|Apple Development|Mac Developer)" || echo "   No code signing certificates found"
        return 1
    fi

    local notarization_success=true

    # Notarize DMG files
    local dmg_files=$(find Build/ -name "*.dmg" -type f 2>/dev/null)
    if [ -n "$dmg_files" ]; then
        print_info "Found DMG files to notarize:"
        echo "$dmg_files" | while read -r dmg_file; do
            print_info "Notarizing DMG: $dmg_file"

            # Check if DMG is signed with Developer ID certificate
            local dmg_signature=$(codesign -dv "$dmg_file" 2>&1)
            if ! echo "$dmg_signature" | grep -q "Developer ID Application"; then
                print_warning "DMG is not signed with Developer ID certificate"
                print_info "Current signature: $dmg_signature"
                print_info "Sign first by running: ./Scripts/sign.sh --dmg"
                return 1
            fi
            if ! echo "$dmg_signature" | grep -q "TeamIdentifier=$TEAM_ID"; then
                print_warning "DMG is not signed with Team ID $TEAM_ID"
                print_info "Current signature: $dmg_signature"
                print_info "Sign first by running: ./Scripts/sign.sh --dmg"
                return 1
            fi

            # Submit DMG for notarization
            print_info "Submitting DMG for notarization: $dmg_file"
            if xcrun notarytool submit "$dmg_file" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" --wait 2>&1 | tee "/tmp/bongocat_notary_dmg_$(basename "$dmg_file").log"; then
                print_success "DMG notarization completed: $dmg_file"

                # Staple the ticket
                print_info "Stapling notarization ticket to DMG..."
                if xcrun stapler staple "$dmg_file"; then
                    print_success "Notarization ticket stapled to DMG: $dmg_file"
                else
                    print_warning "Failed to staple notarization ticket to DMG: $dmg_file"
                fi
            else
                submission_id=$(grep "id:" /tmp/bongocat_notary_dmg_$(basename "$dmg_file").log | head -n 1 | awk '{print $2}')
                print_info "DMG notarization log:"
                xcrun notarytool log "$submission_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID"
                print_error "DMG notarization failed: $dmg_file"
                notarization_success=false
            fi
        done
    else
        print_warning "No DMG files found to notarize"
    fi

    # Notarize PKG files
    local pkg_files=$(find Build/ -name "*.pkg" -type f 2>/dev/null)
    if [ -n "$pkg_files" ]; then
        print_info "Found PKG files to notarize:"
        echo "$pkg_files" | while read -r pkg_file; do
            print_info "Notarizing PKG: $pkg_file"

            # Check if PKG is signed
            if ! pkgutil --check-signature "$pkg_file" 2>/dev/null | grep -q "signed"; then
                print_warning "PKG is not signed, sign first by running ./Scripts/sign.sh --pkg"
                return 1
            fi

            # Submit PKG for notarization
            print_info "Submitting PKG for notarization: $pkg_file"
            if xcrun notarytool submit "$pkg_file" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" --wait 2>&1 | tee "/tmp/bongocat_notary_pkg_$(basename "$pkg_file").log"; then
                print_success "PKG notarization completed: $pkg_file"

                # Staple the ticket
                print_info "Stapling notarization ticket to PKG..."
                if xcrun stapler staple "$pkg_file"; then
                    print_success "Notarization ticket stapled to PKG: $pkg_file"
                else
                    print_warning "Failed to staple notarization ticket to PKG: $pkg_file"
                fi
            else
                submission_id=$(grep "id:" /tmp/bongocat_notary_pkg_$(basename "$pkg_file").log | head -n 1 | awk '{print $2}')
                print_info "PKG notarization log:"
                xcrun notarytool log "$submission_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID"
                print_error "PKG notarization failed: $pkg_file"
                notarization_success=false
            fi
        done
    else
        print_warning "No PKG files found to notarize"
    fi

    # Check if any files were found
    if [ -z "$dmg_files" ] && [ -z "$pkg_files" ]; then
        print_error "No DMG or PKG files found to notarize"
        print_info "Run ./Scripts/package.sh --dmg or ./Scripts/package.sh --pkg first"
        return 1
    fi

    if [ "$notarization_success" = true ]; then
        print_success "All notarization tasks completed successfully!"
        return 0
    else
        print_error "Some notarization tasks failed!"
        return 1
    fi
}

# Function to notarize only DMG files
notarize_dmg_only() {
    print_info "Notarizing DMG files only..."

    # Check if we have notarytool available
    if ! xcrun notarytool --version &> /dev/null; then
        print_error "notarytool not available. Install Xcode command line tools:"
        echo "   xcode-select --install"
        return 1
    fi

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

    # Check for Developer ID certificate (required for notarization)
    if ! get_developer_id_certificate > /dev/null; then
        print_error "No Developer ID certificate found"
        echo ""
        echo "💡 You need a Developer ID certificate for notarization:"
        echo "   1. Join Apple Developer Program"
        echo "   2. Create a Developer ID certificate in Xcode"
        echo "   3. Download and install the certificate"
        echo ""
        echo "🔍 Available certificates:"
        security find-identity -v -p codesigning | grep -E "(Developer ID|Mac App Distribution|Apple Development|Mac Developer)" || echo "   No code signing certificates found"
        return 1
    fi

    # Notarize DMG files
    local dmg_files=$(find Build/ -name "*.dmg" -type f 2>/dev/null)
    if [ -n "$dmg_files" ]; then
        print_info "Found DMG files to notarize:"
        echo "$dmg_files" | while read -r dmg_file; do
            print_info "Notarizing DMG: $dmg_file"

            # Check if DMG is signed with Developer ID certificate
            local dmg_signature=$(codesign -dv "$dmg_file" 2>&1)
            if ! echo "$dmg_signature" | grep -q "TeamIdentifier=$TEAM_ID"; then
                print_warning "DMG is not signed with Team ID $TEAM_ID"
                print_info "Current signature: $dmg_signature"
                print_info "Sign first by running: ./Scripts/sign.sh --dmg"
                return 1
            fi

            # Submit DMG for notarization
            print_info "Submitting DMG for notarization: $dmg_file"
            # Submit DMG for notarization and capture output
            xcrun notarytool submit "$dmg_file" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" --wait 2>&1 | tee "/tmp/bongocat_notary_dmg_$(basename "$dmg_file").log"
            notary_status=$(grep -E "status:" /tmp/bongocat_notary_dmg_$(basename "$dmg_file").log | awk '{print $2}' | tail -n1)

            if [ "$notary_status" = "Accepted" ] || [ "$notary_status" = "success" ] || [ "$notary_status" = "Valid" ]; then
                print_success "DMG notarization completed: $dmg_file"

                # Staple the ticket
                print_info "Stapling notarization ticket to DMG..."
                if xcrun stapler staple "$dmg_file"; then
                    print_success "Notarization ticket stapled to DMG: $dmg_file"
                else
                    print_warning "Failed to staple notarization ticket to DMG: $dmg_file"
                fi
            else
                submission_id=$(grep "id:" /tmp/bongocat_notary_dmg_$(basename "$dmg_file").log | head -n 1 | awk '{print $2}')
                print_info "DMG notarization log:"
                xcrun notarytool log "$submission_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID"
                print_error "DMG notarization failed: $dmg_file"
                return 1
            fi
        done
    else
        print_error "No DMG files found to notarize"
        print_info "Run ./Scripts/package.sh --dmg first"
        return 1
    fi

    print_success "DMG notarization completed successfully!"
    return 0
}

# Function to notarize only PKG files
notarize_pkg_only() {
    print_info "Notarizing PKG files only..."

    # Check if we have notarytool available
    if ! xcrun notarytool --version &> /dev/null; then
        print_error "notarytool not available. Install Xcode command line tools:"
        echo "   xcode-select --install"
        return 1
    fi

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

    # Check for Developer ID certificate (required for notarization)
    if ! get_developer_id_certificate > /dev/null; then
        print_error "No Developer ID certificate found"
        echo ""
        echo "💡 You need a Developer ID certificate for notarization:"
        echo "   1. Join Apple Developer Program"
        echo "   2. Create a Developer ID certificate in Xcode"
        echo "   3. Download and install the certificate"
        echo ""
        echo "🔍 Available certificates:"
        security find-identity -v -p codesigning | grep -E "(Developer ID|Mac App Distribution|Apple Development|Mac Developer)" || echo "   No code signing certificates found"
        return 1
    fi

    # Notarize PKG files
    local pkg_files=$(find Build/ -name "*.pkg" -type f 2>/dev/null)
    if [ -n "$pkg_files" ]; then
        print_info "Found PKG files to notarize:"
        echo "$pkg_files" | while read -r pkg_file; do
            print_info "Notarizing PKG: $pkg_file"

            # Check if PKG is signed
            if ! pkgutil --check-signature "$pkg_file" 2>/dev/null | grep -q "signed"; then
                print_warning "PKG is not signed, sign first by running ./Scripts/sign.sh --pkg"
                return 1
            fi

            # Submit PKG for notarization
            print_info "Submitting PKG for notarization: $pkg_file"

            # Submit PKG for notarization and capture output
            xcrun notarytool submit "$pkg_file" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" --wait 2>&1 | tee "/tmp/bongocat_notary_pkg_$(basename "$pkg_file").log"
            notary_status=$(grep -E "status:" /tmp/bongocat_notary_pkg_$(basename "$pkg_file").log | awk '{print $2}' | tail -n1)

            if [ "$notary_status" = "Accepted" ] || [ "$notary_status" = "success" ] || [ "$notary_status" = "Valid" ]; then
                print_success "PKG notarization completed: $pkg_file"

                # Staple the ticket
                print_info "Stapling notarization ticket to PKG..."
                if xcrun stapler staple "$pkg_file"; then
                    print_success "Notarization ticket stapled to PKG: $pkg_file"
                else
                    print_warning "Failed to staple notarization ticket to PKG: $pkg_file"
                fi
            else
                submission_id=$(grep "id:" /tmp/bongocat_notary_pkg_$(basename "$pkg_file").log | head -n 1 | awk '{print $2}')
                print_info "PKG notarization log:"
                xcrun notarytool log "$submission_id" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID"
                print_error "PKG notarization failed: $pkg_file"
                return 1
            fi
        done
    else
        print_error "No PKG files found to notarize"
        print_info "Run ./Scripts/package.sh --pkg first"
        return 1
    fi

    print_success "PKG notarization completed successfully!"
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --app|-a)
            SIGN_APP=true
            shift
            ;;
        --dmg|-d)
            SIGN_DMG=true
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
        --notarize-dmg)
            NOTARIZE_DMG=true
            shift
            ;;
        --notarize-pkg)
            NOTARIZE_PKG=true
            shift
            ;;
        --all|-A)
            SIGN_APP=true
            SIGN_DMG=true
            SIGN_PKG=true
            NOTARIZE_APP=true
            shift
            ;;
        --adhoc|-h)
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
if [ "$SIGN_APP" = false ] && [ "$SIGN_DMG" = false ] && [ "$SIGN_PKG" = false ] && [ "$NOTARIZE_APP" = false ] && [ "$NOTARIZE_DMG" = false ] && [ "$NOTARIZE_PKG" = false ]; then
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

# Sign DMG if requested
if [ "$SIGN_DMG" = true ]; then
    sign_dmg
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

# Notarize DMG only if requested
if [ "$NOTARIZE_DMG" = true ]; then
    notarize_dmg_only
    echo ""
fi

# Notarize PKG only if requested
if [ "$NOTARIZE_PKG" = true ]; then
    notarize_pkg_only
    echo ""
fi

echo ""
print_success "Signing completed successfully!"