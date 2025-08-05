#!/bin/bash

# BongoCat App Store Upload Script (Complete)
# Uses validation before upload with proper altool commands

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

APP_NAME="BongoCat"
BUNDLE_ID="com.leaptech.bongocat"

echo "🍎 BongoCat App Store Upload Script (Complete)"
echo "=============================================="
echo ""

# Check required environment variables
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
    print_error "Apple ID credentials not set"
    echo ""
    echo "💡 Set environment variables:"
    echo "   export APPLE_ID='your-apple-id@example.com'"
    echo "   export APPLE_ID_PASSWORD='your-app-specific-password'"
    exit 1
fi

print_success "Apple ID credentials found: $APPLE_ID"

# Check if app bundle exists
app_bundle="Build/package/${APP_NAME}.app"
if [ ! -d "$app_bundle" ]; then
    print_error "App bundle not found: $app_bundle"
    echo ""
    echo "💡 Create the app bundle first:"
    echo "   ./run.sh --app-store"
    exit 1
fi

print_success "App bundle found: $app_bundle"

# Create temporary zip
temp_zip="/tmp/${APP_NAME}-upload.zip"
print_info "Creating temporary zip for upload..."
ditto -c -k --keepParent "$app_bundle" "$temp_zip"

print_success "Temporary zip created: $temp_zip"

# Step 1: Validate the app
echo ""
print_info "Step 1: Validating app..."
validation_output=$(xcrun altool --validate-app \
    -f "$temp_zip" \
    -t macos \
    -u "$APPLE_ID" \
    -p "$APPLE_ID_PASSWORD" \
    --output-format xml 2>&1)

validation_exit_code=$?

if [ $validation_exit_code -eq 0 ]; then
    print_success "App validation passed!"
else
    print_error "App validation failed:"
    echo "$validation_output"
    echo ""

    # Check for specific validation errors
    if echo "$validation_output" | grep -q "platform iOS App"; then
        print_error "App was created for iOS instead of macOS"
        echo ""
        echo "💡 Solution: Delete the iOS app and create a new macOS app"
        echo ""
        echo "📋 Steps to fix:"
        echo "   1. Go to https://appstoreconnect.apple.com"
        echo "   2. Click 'My Apps'"
        echo "   3. Find your BongoCat app"
        echo "   4. Click '...' next to the app"
        echo "   5. Select 'Delete App'"
        echo "   6. Create a new app:"
        echo "      • Click '+' to add new app"
        echo "      • Select 'macOS' (not iOS!)"
        echo "      • Name: BongoCat"
        echo "      • Bundle ID: $BUNDLE_ID"
        echo "      • SKU: bongocat-macos"
        echo "   7. Run this script again"
    else
        echo "💡 Check the validation output above for specific issues"
    fi

    rm -f "$temp_zip"
    exit 1
fi

# Step 2: Upload the app
echo ""
print_info "Step 2: Uploading app to App Store Connect..."
upload_output=$(xcrun altool --upload-app \
    -f "$temp_zip" \
    -t osx \
    -u "$APPLE_ID" \
    -p "$APPLE_ID_PASSWORD" \
    --output-format xml 2>&1)

upload_exit_code=$?

# Clean up temp file
rm -f "$temp_zip"

if [ $upload_exit_code -eq 0 ]; then
    print_success "Upload completed successfully!"
    echo ""
    echo "📋 Upload details:"
    echo "$upload_output" | grep -E "(No errors|RequestUUID|Product ID)"
    echo ""
    echo "🎉 Next steps:"
    echo "   1. Check App Store Connect for your uploaded build"
    echo "   2. Complete the submission process in App Store Connect"
    echo "   3. Add metadata, screenshots, and descriptions"
    echo "   4. Submit for review"
else
    print_error "Upload failed:"
    echo "$upload_output"
    echo ""
    echo "💡 Alternative upload methods:"
    echo "   • Use Transporter app (download from App Store)"
    echo "   • Use Xcode Organizer (Window > Organizer)"
    echo "   • Use Application Loader (legacy)"
fi