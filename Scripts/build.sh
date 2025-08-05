#!/bin/bash

# BongoCat Build Script
set -xe  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Parse command line arguments
BUILD_CONFIG="debug"
if [ "$1" = "release" ] || [ "$1" = "-r" ] || [ "$1" = "--release" ]; then
    BUILD_CONFIG="release"
elif [ "$1" = "debug" ] || [ "$1" = "-d" ] || [ "$1" = "--debug" ]; then
    BUILD_CONFIG="debug"
elif [ -n "$1" ]; then
    print_error "Invalid build configuration: $1"
    echo ""
    echo "Usage: $0 [debug|release|-d|-r|--debug|--release]"
    echo "  debug (default): Build for development with debug symbols"
    echo "  release:         Build optimized for production"
    exit 1
fi

print_info "Building BongoCat in $BUILD_CONFIG mode..."

# Source environment variables for production builds
if [ "$BUILD_CONFIG" = "release" ]; then
    print_info "Production build detected, loading environment variables..."
    if [ -f ".env" ]; then
        print_info "Sourcing .env file..."
        source .env
        print_success "Environment variables loaded successfully"
    else
        print_error "Production build requires .env file but it was not found!"
        print_error "Please create a .env file in the project root with necessary environment variables"
        exit 1
    fi

    # Check if posthog api key and host are set
    if [ -n "$POSTHOG_API_KEY" ] && [ -n "$POSTHOG_HOST" ]; then
        print_info "Posthog API key and host are set"
    else
        print_error "Posthog API key and host are not set"
        print_error "Please set them in the .env file"
        exit 1
    fi

    print_info "Cleaning previous build artifacts for fresh production build..."
    swift package clean

    if [ "$BUILD_CONFIG" = "release" ]; then
        print_info "Building universal binary for App Store (Intel + Apple Silicon)..."

        # Build for Intel
        print_info "Building for Intel (x86_64)..."
        swift build --configuration release --triple x86_64-apple-macos13.0

        # Build for Apple Silicon
        print_info "Building for Apple Silicon (arm64)..."
        swift build --configuration release --triple arm64-apple-macos13.0

        # Create universal binary
        print_info "Creating universal binary..."
        lipo -create -output .build/release/BongoCat \
            .build/x86_64-apple-macos/release/BongoCat \
            .build/arm64-apple-macos/release/BongoCat

        print_success "Universal binary created successfully!"
        BUILD_COMMAND="echo 'Universal binary already built'"
    else
        BUILD_COMMAND="swift build"
    fi
else
    BUILD_COMMAND="swift build"
fi

if $BUILD_COMMAND; then
    print_success "Build completed successfully in $BUILD_CONFIG mode!"
    echo ""
    if [ "$BUILD_CONFIG" = "debug" ]; then
        print_info "Run with: swift run"
        print_info "Or package with: ./Scripts/package_app.sh"
    else
        print_info "Run with: swift run --configuration release"
        print_info "Package with: ./Scripts/package_app.sh"
        print_info "Binary location: .build/release/BongoCat"
    fi
else
    print_error "Build failed!"
    exit 1
fi