#!/bin/bash

# BangoCat Accessibility Permission Clear Script
# This script helps clear accessibility permissions for BangoCat

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🐱 BangoCat Accessibility Permission Clear Tool"
echo "=============================================="
echo ""

print_info "This script will help you clear accessibility permissions for BangoCat"
echo "This is useful if you're having issues with accessibility permissions after reinstalling."
echo ""

# Check if BangoCat is running
if pgrep -f "BangoCat" > /dev/null; then
    print_warning "BangoCat is currently running"
    echo "Please quit BangoCat before proceeding."
    echo "You can quit it from the menu bar icon or by pressing Cmd+Q"
    echo ""
    read -p "Press Enter when BangoCat is quit..."
fi

print_info "Opening System Preferences to Accessibility settings..."
echo ""

# Open System Preferences to Accessibility
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
print_info "Instructions:"
echo "1. In System Preferences, find 'BangoCat' in the Accessibility list"
echo "2. If it's there, uncheck it or remove it"
echo "3. Close System Preferences"
echo "4. Re-run BangoCat and grant permissions when prompted"
echo ""

print_success "System Preferences opened!"
echo ""
print_info "After clearing the permissions, you can:"
echo "• Run BangoCat again to grant fresh permissions"
echo "• Use the packaged DMG for consistent app identity"
echo "• The app is now code signed to maintain consistent identity"
echo ""

echo "�� Happy bongoing!"