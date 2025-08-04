#!/bin/bash

# Test script for BongoCat update system
# This script helps diagnose update-related issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔍 BongoCat Update System Test"
echo "================================"

# Check current version
print_info "Checking current version..."
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null || echo "unknown")
print_success "Current version: $CURRENT_VERSION"

# Test GitHub API connectivity
print_info "Testing GitHub API connectivity..."
API_RESPONSE=$(curl -s -w "%{http_code}" "https://api.github.com/repos/Gamma-Software/BongoCat-mac/releases/latest" -o /tmp/latest_release.json)
HTTP_CODE="${API_RESPONSE: -3}"

if [ "$HTTP_CODE" = "200" ]; then
    print_success "GitHub API accessible (HTTP $HTTP_CODE)"

    # Parse latest version
    LATEST_VERSION=$(cat /tmp/latest_release.json | jq -r '.tag_name' | sed 's/v//')
    print_success "Latest version: $LATEST_VERSION"

    # Check if update is needed
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        print_warning "Update available: $CURRENT_VERSION → $LATEST_VERSION"
    else
        print_success "App is up to date"
    fi

    # Check for DMG assets
    DMG_ASSETS=$(cat /tmp/latest_release.json | jq -r '.assets[] | select(.name | endswith(".dmg")) | .name' | head -1)
    if [ -n "$DMG_ASSETS" ]; then
        print_success "DMG assets found: $DMG_ASSETS"
    else
        print_error "No DMG assets found in latest release"
    fi

else
    print_error "GitHub API not accessible (HTTP $HTTP_CODE)"
fi

# Test download URL
print_info "Testing download URL..."
DOWNLOAD_URL="https://github.com/Gamma-Software/BongoCat-mac/releases/download/v$LATEST_VERSION/BongoCat-$LATEST_VERSION.dmg"
DOWNLOAD_RESPONSE=$(curl -s -I "$DOWNLOAD_URL" | head -1 | cut -d' ' -f2)

if [ "$DOWNLOAD_RESPONSE" = "302" ] || [ "$DOWNLOAD_RESPONSE" = "200" ]; then
    print_success "Download URL accessible (HTTP $DOWNLOAD_RESPONSE)"
else
    print_error "Download URL not accessible (HTTP $DOWNLOAD_RESPONSE)"
fi

# Test network permissions
print_info "Testing network permissions..."
if curl -s "https://api.github.com" > /dev/null; then
    print_success "Network permissions OK"
else
    print_error "Network permissions issue"
fi

# Check app permissions
print_info "Checking app permissions..."
if [ -d "/Applications/BongoCat.app" ]; then
    print_success "BongoCat found in Applications"

    # Check if app can be replaced
    if [ -w "/Applications" ]; then
        print_success "Write permission to Applications folder"
    else
        print_warning "No write permission to Applications folder (may need sudo for installation)"
    fi
else
    print_warning "BongoCat not found in Applications folder"
fi

# Clean up
rm -f /tmp/latest_release.json

echo ""
echo "🎯 Test Summary:"
echo "================="
echo "• Current version: $CURRENT_VERSION"
echo "• Latest version: $LATEST_VERSION"
echo "• GitHub API: HTTP $HTTP_CODE"
echo "• Download URL: HTTP $DOWNLOAD_RESPONSE"
echo ""
echo "💡 If you're experiencing update issues:"
echo "1. Check your internet connection"
echo "2. Ensure BongoCat has network permissions"
echo "3. Try downloading manually from GitHub releases"
echo "4. Check the app logs for detailed error messages"