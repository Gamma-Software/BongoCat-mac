#!/bin/bash

# BongoCat Build Script - All-in-one build, test, run and install
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

# Default values
BUILD_CONFIG="debug"
RUN_TESTS=false
RUN_APP=false
INSTALL_LOCAL=false
CLEAN_BUILD=false

# Function to show usage
show_usage() {
    echo "🐱 BongoCat Build Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Build Options:"
    echo "  --debug, -d          Build in debug mode (default)"
    echo "  --release, -r        Build in release mode"
    echo "  --clean, -c          Clean build artifacts before building"
    echo ""
    echo "Action Options:"
    echo "  --test, -t           Run tests after building"
    echo "  --run, -u            Run the app after building"
    echo "  --install, -i        Install app locally after building"
    echo ""
    echo "Combined Actions:"
    echo "  --test-run, -tr      Build, test, and run"
    echo "  --test-install, -ti  Build, test, and install locally"
    echo "  --run-install, -ri   Build, run, and install locally"
    echo "  --all, -a            Build, test, run, and install locally"
    echo ""
    echo "Examples:"
    echo "  $0 --debug --test"
    echo "  $0 --release --run"
    echo "  $0 --all"
    echo "  $0 -r -t -u -i"
    echo ""
    echo "🔧 Build Modes:"
    echo "  • Debug: Development build with debug symbols"
    echo "  • Release: Optimized build for production"
    echo ""
    echo "🧪 Testing:"
    echo "  • Runs all unit tests"
    echo "  • Shows test results and coverage"
    echo ""
    echo "🚀 Running:"
    echo "  • Launches the app directly"
    echo "  • Shows app output in terminal"
    echo ""
    echo "📦 Installation:"
    echo "  • Installs app to /Applications"
    echo "  • Requires sudo for system installation"
}

# Function to clean build artifacts
clean_build() {
    print_info "Cleaning build artifacts..."
    rm -rf .build
    rm -rf Build
    print_success "Build artifacts cleaned"
}

# Function to build the app
build_app() {
    local config=$1

    print_info "Building BongoCat in $config mode..."

    if [ "$config" = "release" ]; then
        # Source environment variables for production builds
        if [ -f ".env" ]; then
            print_info "Sourcing .env file..."
            source .env
            print_success "Environment variables loaded"
        else
            print_warning "No .env file found for release build"
        fi

        print_info "Building universal binary for production (Intel + Apple Silicon)..."

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
    else
        print_info "Building debug version..."
        swift build --configuration debug
    fi

    print_success "Build completed successfully in $config mode!"
}

# Function to run tests
run_tests() {
    print_info "Running tests..."

    if swift test; then
        print_success "All tests passed!"
    else
        print_error "Tests failed!"
        exit 1
    fi
}

# Function to run the app
run_app() {
    local config=$1

    print_info "Running BongoCat app..."

    if [ "$config" = "release" ]; then
        swift run --configuration release
    else
        swift run
    fi
}

# Function to install app locally
install_app() {
    print_info "Installing BongoCat locally..."

    # Check if Build directory exists
    if [ ! -d "Build" ]; then
        print_error "Build directory not found. Please build the app first."
        exit 1
    fi

    # Look for the app bundle
    local app_bundle=""
    if [ -d "Build/package/BongoCat.app" ]; then
        app_bundle="Build/package/BongoCat.app"
    elif [ -d "Build/BongoCat.app" ]; then
        app_bundle="Build/BongoCat.app"
    else
        print_error "App bundle not found. Please package the app first."
        exit 1
    fi

    print_info "Installing $app_bundle to /Applications..."

    # Copy to Applications
    if sudo cp -R "$app_bundle" /Applications/; then
        print_success "BongoCat installed to /Applications successfully!"
        print_info "You can now launch BongoCat from Applications folder"
    else
        print_error "Failed to install BongoCat"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug|-d)
            BUILD_CONFIG="debug"
            shift
            ;;
        --release|-r)
            BUILD_CONFIG="release"
            shift
            ;;
        --clean|-c)
            CLEAN_BUILD=true
            shift
            ;;
        --test|-t)
            RUN_TESTS=true
            shift
            ;;
        --run|-u)
            RUN_APP=true
            shift
            ;;
        --install|-i)
            INSTALL_LOCAL=true
            shift
            ;;
        --test-run|-tr)
            RUN_TESTS=true
            RUN_APP=true
            shift
            ;;
        --test-install|-ti)
            RUN_TESTS=true
            INSTALL_LOCAL=true
            shift
            ;;
        --run-install|-ri)
            RUN_APP=true
            INSTALL_LOCAL=true
            shift
            ;;
        --all|-a)
            RUN_TESTS=true
            RUN_APP=true
            INSTALL_LOCAL=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
echo "🐱 BongoCat Build Script"
echo "========================"
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

# Check if Xcode Command Line Tools are installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode Command Line Tools not found"
    echo "Please install with: xcode-select --install"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Please run this script from the BongoCat-mac directory"
    exit 1
fi

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    clean_build
fi

# Build the app
build_app "$BUILD_CONFIG"

# Run tests if requested
if [ "$RUN_TESTS" = true ]; then
    run_tests
fi

# Run app if requested
if [ "$RUN_APP" = true ]; then
    run_app "$BUILD_CONFIG"
fi

# Install locally if requested
if [ "$INSTALL_LOCAL" = true ]; then
    install_app
fi

echo ""
print_success "Build script completed successfully!"
echo ""
print_info "Next steps:"
if [ "$BUILD_CONFIG" = "debug" ]; then
    print_info "  • Package: ./Scripts/package.sh"
    print_info "  • Sign: ./Scripts/sign.sh"
else
    print_info "  • Package: ./Scripts/package.sh"
    print_info "  • Sign: ./Scripts/sign.sh"
    print_info "  • Push: ./Scripts/push.sh"
fi