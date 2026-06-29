#!/bin/bash
# Build and run the modded BongoCat from source

# Always run from the repo root regardless of where the script is called from
cd "$(dirname "$0")"

PROJECT="app/BongoCat Overlay.xcodeproj"
SCHEME="BongoCat"
DERIVED="/tmp/BongoCatDev"
APP="$DERIVED/Build/Products/Debug/Bongo Cat Overlay.app"

echo "🐱 Building BongoCat..."
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"

if [ ! -d "$APP" ]; then
  echo "❌ Build failed — app not found at $APP"
  exit 1
fi

echo "🐱 Killing existing instance..."
pkill -f "Bongo Cat" 2>/dev/null || true
sleep 1

echo "🐱 Launching BongoCat..."
"$APP/Contents/MacOS/Bongo Cat Overlay" &
disown
echo "✅ Launched!"
