#!/bin/bash

# BongoCat App Store Build Script
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

# App Store specific variables
APP_NAME="BongoCat"
BUNDLE_ID="com.leaptech.bongocat"
TEAM_ID=""  # Will be set from environment or prompt
APP_STORE_PROVISIONING_PROFILE=""  # Will be set from environment or prompt
DISTRIBUTION_CERTIFICATE=""  # Will be set from environment or prompt

# Check for required environment variables
if [ -z "$TEAM_ID" ]; then
    if [ -f ".env" ]; then
        source .env
    fi
fi

# Prompt for missing credentials
if [ -z "$TEAM_ID" ]; then
    echo ""
    print_warning "Apple Developer Team ID not found"
    echo "💡 You can set it in .env file or enter it now:"
    read -p "Enter your Apple Developer Team ID: " TEAM_ID
fi

if [ -z "$DISTRIBUTION_CERTIFICATE" ]; then
    echo ""
    print_warning "Distribution Certificate not found"
    echo "💡 You can set DISTRIBUTION_CERTIFICATE in .env file or enter it now:"
    read -p "Enter your Distribution Certificate name (e.g., 'Apple Distribution'): " DISTRIBUTION_CERTIFICATE
fi

if [ -z "$APP_STORE_PROVISIONING_PROFILE" ]; then
    echo ""
    print_warning "App Store Provisioning Profile not found"
    echo "💡 You can set APP_STORE_PROVISIONING_PROFILE in .env file or enter it now:"
    read -p "Enter your App Store Provisioning Profile name: " APP_STORE_PROVISIONING_PROFILE
fi

print_info "Starting App Store build process..."
print_info "Team ID: $TEAM_ID"
print_info "Certificate: $DISTRIBUTION_CERTIFICATE"
print_info "Provisioning Profile: $APP_STORE_PROVISIONING_PROFILE"

# Clean previous builds
print_info "Cleaning previous builds..."
swift package clean
rm -rf "Build/appstore"

# Build for App Store
print_info "Building for App Store..."
swift build -c release

# Create app bundle structure
print_info "Creating App Store app bundle..."
mkdir -p "Build/appstore/${APP_NAME}.app/Contents/MacOS"
mkdir -p "Build/appstore/${APP_NAME}.app/Contents/Resources"

# Copy executable
cp ".build/release/${APP_NAME}" "Build/appstore/${APP_NAME}.app/Contents/MacOS/"

# Copy Info.plist with App Store modifications
print_info "Creating App Store Info.plist..."
cat > "Build/appstore/${APP_NAME}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleShortVersionString</key>
    <string>1.5.6</string>
    <key>CFBundleVersion</key>
    <string>1.5.6.202507302245</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>
            <key>api.github.com</key>
            <dict>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
                <key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
        </dict>
    </dict>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleResourceSpecification</key>
    <string>ResourceRules.plist</string>
</dict>
</plist>
EOF

# Copy resources
print_info "Copying app resources..."
if [ -d "Sources/BongoCat/Resources" ]; then
    cp -r "Sources/BongoCat/Resources/"* "Build/appstore/${APP_NAME}.app/Contents/Resources/"
fi

# Copy app icons
if [ -f "Assets/Icons/AppIcon.icns" ]; then
    cp "Assets/Icons/AppIcon.icns" "Build/appstore/${APP_NAME}.app/Contents/Resources/"
fi

# Copy entitlements
if [ -f "BongoCat.entitlements" ]; then
    cp "BongoCat.entitlements" "Build/appstore/${APP_NAME}.app/Contents/"
fi

# Make executable runnable
chmod +x "Build/appstore/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# Code sign for App Store
print_info "Code signing for App Store..."
if [ -n "$DISTRIBUTION_CERTIFICATE" ] && [ -n "$TEAM_ID" ]; then
    # Sign with distribution certificate
    codesign --force --sign "${DISTRIBUTION_CERTIFICATE}" \
             --entitlements "BongoCat.entitlements" \
             --options runtime \
             "Build/appstore/${APP_NAME}.app"

    print_success "App signed with distribution certificate"
else
    print_warning "Distribution certificate not available, using ad-hoc signing"
    codesign --force --sign - \
             --entitlements "BongoCat.entitlements" \
             --options runtime \
             "Build/appstore/${APP_NAME}.app"
fi

# Verify code signing
print_info "Verifying code signature..."
if codesign --verify --verbose "Build/appstore/${APP_NAME}.app"; then
    print_success "Code signature verified"
else
    print_error "Code signature verification failed"
    exit 1
fi

# Create App Store package
print_info "Creating App Store package..."
mkdir -p "Build/appstore/package"

# Create .pkg file for App Store
pkgbuild --component "Build/appstore/${APP_NAME}.app" \
         --install-location "/Applications" \
         --identifier "${BUNDLE_ID}" \
         --version "1.5.6" \
         "Build/appstore/package/${APP_NAME}.pkg"

print_success "App Store package created: Build/appstore/package/${APP_NAME}.pkg"

# Create .app file for direct upload
print_info "Creating .app file for App Store Connect..."
cp -R "Build/appstore/${APP_NAME}.app" "Build/appstore/package/"

print_success "App Store build completed!"
echo ""
echo "📦 App Store files created:"
echo "   • Build/appstore/package/${APP_NAME}.pkg (for App Store Connect)"
echo "   • Build/appstore/package/${APP_NAME}.app (for direct upload)"
echo ""
echo "🚀 Next steps:"
echo "   1. Upload to App Store Connect using Xcode or Application Loader"
echo "   2. Configure app metadata in App Store Connect"
echo "   3. Submit for review"
echo ""
echo "💡 Note: This build includes sandboxing and App Store requirements"
echo "   • Accessibility permissions will need to be granted manually by users"
echo "   • Users will need to enable accessibility access in System Preferences"