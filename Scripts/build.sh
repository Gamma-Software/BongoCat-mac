#!/bin/bash

# BangoCat Build Script
set -e

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

print_info "Building BangoCat..."

if swift build; then
    print_success "Build completed successfully!"
    echo ""
    print_info "Run with: swift run"
    print_info "Or package with: ./Scripts/package_app.sh"
else
    print_error "Build failed!"
    exit 1
fi