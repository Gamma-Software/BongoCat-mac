#!/bin/bash

echo "Testing app validation..."

# Create temp zip
ditto -c -k --keepParent "Build/package/BongoCat.app" "/tmp/BongoCat-validate.zip"

# Test validation
echo "Running validation..."
result=$(xcrun altool --validate-app \
    -f "/tmp/BongoCat-validate.zip" \
    -t macos \
    -u "valentin.rudloff.perso@gmail.com" \
    -p "aitt-voco-vrjy-bzmm" \
    --output-format xml 2>&1)

exit_code=$?

echo "Exit code: $exit_code"
echo "Result:"
echo "$result"

# Clean up
rm -f "/tmp/BongoCat-validate.zip"