#!/bin/bash

# BongoCat App Store Preparation Script
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

echo "🐱 BongoCat App Store Preparation Checklist"
echo "=========================================="
echo ""

# Check 1: Apple Developer Program Membership
print_info "1. Checking Apple Developer Program membership..."
echo "   • You need an active Apple Developer Program membership ($99/year)"
echo "   • Visit: https://developer.apple.com/programs/"
echo "   • This is required for App Store submission"
echo ""

# Check 2: Bundle Identifier
print_info "2. Checking bundle identifier..."
BUNDLE_ID="com.leaptech.bongocat"
echo "   • Current bundle ID: $BUNDLE_ID"
echo "   • Make sure this is registered in your Apple Developer account"
echo "   • Visit: https://developer.apple.com/account/resources/identifiers/list"
echo ""

# Check 3: Certificates and Profiles
print_info "3. Checking certificates and profiles..."
echo "   • You need a Distribution Certificate"
echo "   • You need an App Store Provisioning Profile"
echo "   • Visit: https://developer.apple.com/account/resources/certificates/list"
echo "   • Visit: https://developer.apple.com/account/resources/profiles/list"
echo ""

# Check 4: App Store Connect Setup
print_info "4. Checking App Store Connect setup..."
echo "   • Create a new app in App Store Connect"
echo "   • Bundle ID: $BUNDLE_ID"
echo "   • Visit: https://appstoreconnect.apple.com/apps"
echo ""

# Check 5: Required Files
print_info "5. Checking required files..."

# Check entitlements file
if [ -f "BongoCat.entitlements" ]; then
    print_success "   • BongoCat.entitlements exists"
else
    print_error "   • BongoCat.entitlements missing"
fi

# Check app icons
if [ -f "Assets/Icons/AppIcon.icns" ]; then
    print_success "   • App icon exists"
else
    print_warning "   • App icon may be missing"
fi

# Check Info.plist
if [ -f "Info.plist" ]; then
    print_success "   • Info.plist exists"
else
    print_error "   • Info.plist missing"
fi

echo ""

# Check 6: Sandboxing Requirements
print_info "6. Checking sandboxing requirements..."
echo "   • App must be sandboxed for App Store"
echo "   • Entitlements file includes necessary permissions"
echo "   • Global input monitoring may need special handling"
echo ""

# Check 7: Accessibility Permissions
print_info "7. Checking accessibility permissions..."
echo "   • App Store apps cannot automatically request accessibility permissions"
echo "   • Users must manually enable in System Preferences"
echo "   • FirstLaunchGuide.swift provides setup instructions"
echo ""

# Check 8: App Store Guidelines
print_info "8. Checking App Store guidelines..."
echo "   • Review: https://developer.apple.com/app-store/review/guidelines/"
echo "   • Ensure app functionality is clear"
echo "   • Provide comprehensive setup instructions"
echo ""

# Check 9: Metadata Requirements
print_info "9. Checking metadata requirements..."
echo "   • App description (see APP_STORE_GUIDE.md)"
echo "   • Screenshots (at least 1, up to 10)"
echo "   • App preview videos (optional)"
echo "   • Keywords for search optimization"
echo ""

# Check 10: Testing Requirements
print_info "10. Checking testing requirements..."
echo "   • Test on clean macOS installation"
echo "   • Test accessibility permission flow"
echo "   • Test all app features with sandboxing"
echo "   • Test on different macOS versions"
echo ""

# Build test
print_info "11. Testing App Store build..."
if [ -f "Scripts/appstore_build.sh" ]; then
    print_success "   • App Store build script exists"
    echo "   • Run: ./Scripts/appstore_build.sh"
else
    print_error "   • App Store build script missing"
fi

echo ""

# Summary
echo "📋 Summary of Required Actions:"
echo "================================"
echo ""
echo "1. ✅ Apple Developer Program membership"
echo "2. ✅ Register bundle identifier: $BUNDLE_ID"
echo "3. ✅ Create Distribution Certificate"
echo "4. ✅ Create App Store Provisioning Profile"
echo "5. ✅ Create app in App Store Connect"
echo "6. ✅ Prepare app metadata and screenshots"
echo "7. ✅ Test sandboxed build thoroughly"
echo "8. ✅ Submit for App Store review"
echo ""

# Environment setup
print_info "Environment Setup:"
echo "Create a .env file with your Apple Developer credentials:"
echo ""
echo "TEAM_ID=\"YOUR_TEAM_ID\""
echo "DISTRIBUTION_CERTIFICATE=\"Apple Distribution\""
echo "APP_STORE_PROVISIONING_PROFILE=\"BongoCat App Store\""
echo "APPLE_ID=\"your-apple-id@example.com\""
echo "APPLE_ID_PASSWORD=\"your-app-specific-password\""
echo ""

# Next steps
print_info "Next Steps:"
echo "1. Complete Apple Developer Program setup"
echo "2. Create certificates and profiles"
echo "3. Set up App Store Connect app"
echo "4. Run: ./Scripts/appstore_build.sh"
echo "5. Upload to App Store Connect"
echo "6. Configure metadata and submit for review"
echo ""

print_success "Preparation checklist completed!"
echo ""
echo "📚 Additional Resources:"
echo "   • APP_STORE_GUIDE.md - Detailed submission guide"
echo "   • https://developer.apple.com/app-store/submissions/"
echo "   • https://developer.apple.com/app-store/review/guidelines/"