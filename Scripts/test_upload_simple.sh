#!/bin/bash

echo "Testing altool upload..."

# Create temp zip
ditto -c -k --keepParent "Build/package/BongoCat.app" "/tmp/BongoCat-test.zip"

# Test upload
echo "Running altool..."
result=$(xcrun altool --upload-app \
    --type macos \
    --file "/tmp/BongoCat-test.zip" \
    --username "valentin.rudloff.perso@gmail.com" \
    --password "aitt-voco-vrjy-bzmm" 2>&1)

exit_code=$?

echo "Exit code: $exit_code"
echo "Result:"
echo "$result"

# Clean up
rm -f "/tmp/BongoCat-test.zip"