#!/bin/bash

# BongoCat macOS Package Creator
# Creates a .pkg file for macOS App Store distribution

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

echo "📦 BongoCat macOS Package Creator"
echo "================================="
echo ""

# Configuration
APP_NAME="BongoCat"
APP_BUNDLE="Build/package/${APP_NAME}.app"
PKG_OUTPUT="Build/${APP_NAME}-$(date +%Y%m%d).pkg"
IDENTIFIER="com.leaptech.bongocat"

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    print_error "App bundle not found: $APP_BUNDLE"
    print_info "Please run the build script first: ./Scripts/package_app.sh --app_store"
    exit 1
fi

print_success "Found app bundle: $APP_BUNDLE"

# Check if app is code signed
if ! codesign -dv "$APP_BUNDLE" &>/dev/null; then
    print_warning "App bundle is not code signed"
    print_info "Signing app bundle..."
    ./Scripts/code_sign.sh
fi

# Create temporary directory for package structure
TEMP_DIR="/tmp/${APP_NAME}-pkg"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR/Applications"

print_info "Creating package structure..."

# Copy app to Applications folder
cp -R "$APP_BUNDLE" "$TEMP_DIR/Applications/"

# Create component plist
COMPONENT_PLIST="$TEMP_DIR/component.plist"
cat > "$COMPONENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
    <dict>
        <key>BundleHasStrictIdentifier</key>
        <true/>
        <key>BundleIsRelocatable</key>
        <false/>
        <key>BundleIsVersionChecked</key>
        <true/>
        <key>BundleOverwriteAction</key>
        <string>upgrade</string>
        <key>RootRelative</key>
        <true/>
        <key>BundleVersion</key>
        <string>1.0</string>
    </dict>
</array>
</plist>
EOF

print_info "Creating .pkg file..."

# Create the package (without signing for now)
productbuild \
    --component "$TEMP_DIR/Applications/${APP_NAME}.app" \
    "/Applications" \
    --identifier "$IDENTIFIER" \
    --version "1.0" \
    "$PKG_OUTPUT"

# Note: For App Store, you need to sign with "3rd Party Mac Developer Installer" certificate
# productbuild --sign "3rd Party Mac Developer Installer" --component "$TEMP_DIR/Applications/${APP_NAME}.app" "/Applications" --identifier "$IDENTIFIER" --version "1.0" "$PKG_OUTPUT"

if [ $? -eq 0 ]; then
    print_success "Package created successfully: $PKG_OUTPUT"
    print_info "Package size: $(du -h "$PKG_OUTPUT" | cut -f1)"
else
    print_error "Failed to create package"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

print_info "Package is ready for App Store upload!"
print_info "Use: ./Scripts/upload_app_store.sh --pkg $PKG_OUTPUT"