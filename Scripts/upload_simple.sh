#!/bin/bash

echo "🍎 BongoCat App Store Upload (Simple)"
echo "====================================="
echo ""

# Load environment
source .env

# Create zip
echo "Creating zip file..."
ditto -c -k --keepParent "Build/package/BongoCat.app" "/tmp/BongoCat-upload.zip"

# Validate
echo ""
echo "Step 1: Validating app..."
xcrun altool --validate-app \
    -f "/tmp/BongoCat-upload.zip" \
    -t macos \
    -u "$APPLE_ID" \
    -p "$APPLE_ID_PASSWORD" \
    --output-format xml

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Validation passed!"
    echo ""
    echo "Step 2: Uploading app..."
    xcrun altool --upload-app \
        -f "/tmp/BongoCat-upload.zip" \
        -t macos \
        -u "$APPLE_ID" \
        -p "$APPLE_ID_PASSWORD" \
        --output-format xml
else
    echo ""
    echo "❌ Validation failed!"
    echo ""
    echo "💡 The app was probably created for iOS instead of macOS."
    echo "   Please delete the iOS app and create a new macOS app in App Store Connect."
fi

# Clean up
rm -f "/tmp/BongoCat-upload.zip"