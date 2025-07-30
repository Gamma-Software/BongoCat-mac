#!/bin/bash

# BangoCat Sample Plugin Generator
# This script creates a sample plugin manifest for testing the plugin system

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

echo "🐱 BangoCat Sample Plugin Generator"
echo "==================================="
echo ""

# Create sample plugin manifest
SAMPLE_MANIFEST='[
  {
    "id": "santa-hat",
    "name": "Santa Hat",
    "description": "Festive Santa hat for your cat",
    "version": "1.0.0",
    "price": 2.99,
    "assets": [
      {
        "name": "Santa Hat",
        "filename": "santa-hat.png",
        "position": {"x": 0, "y": -20},
        "scale": 1.0,
        "zIndex": 10,
        "tintColor": null
      }
    ],
    "positioning": {
      "anchorPoint": {"x": 0.5, "y": 1.0},
      "offset": {"x": 0, "y": 0},
      "rotationOffset": 0,
      "scaleWithCat": true
    },
    "requirements": {
      "minimumAppVersion": "1.5.0",
      "minimumOSVersion": "13.0",
      "dependencies": []
    },
    "metadata": {
      "author": "BangoCat Team",
      "category": "Holiday",
      "tags": ["christmas", "holiday", "festive"],
      "releaseDate": "2024-12-01T00:00:00Z",
      "lastUpdated": "2024-12-01T00:00:00Z"
    }
  },
  {
    "id": "wizard-hat",
    "name": "Wizard Hat",
    "description": "Magical wizard hat for your cat",
    "version": "1.0.0",
    "price": 3.99,
    "assets": [
      {
        "name": "Wizard Hat",
        "filename": "wizard-hat.png",
        "position": {"x": 0, "y": -25},
        "scale": 1.0,
        "zIndex": 10,
        "tintColor": null
      }
    ],
    "positioning": {
      "anchorPoint": {"x": 0.5, "y": 1.0},
      "offset": {"x": 0, "y": 0},
      "rotationOffset": 0,
      "scaleWithCat": true
    },
    "requirements": {
      "minimumAppVersion": "1.5.0",
      "minimumOSVersion": "13.0",
      "dependencies": []
    },
    "metadata": {
      "author": "BangoCat Team",
      "category": "Fantasy",
      "tags": ["wizard", "magic", "fantasy"],
      "releaseDate": "2024-12-01T00:00:00Z",
      "lastUpdated": "2024-12-01T00:00:00Z"
    }
  },
  {
    "id": "sunglasses",
    "name": "Sunglasses",
    "description": "Cool sunglasses for your cat",
    "version": "1.0.0",
    "price": 1.99,
    "assets": [
      {
        "name": "Sunglasses",
        "filename": "sunglasses.png",
        "position": {"x": 0, "y": 5},
        "scale": 1.0,
        "zIndex": 5,
        "tintColor": null
      }
    ],
    "positioning": {
      "anchorPoint": {"x": 0.5, "y": 0.5},
      "offset": {"x": 0, "y": 0},
      "rotationOffset": 0,
      "scaleWithCat": true
    },
    "requirements": {
      "minimumAppVersion": "1.5.0",
      "minimumOSVersion": "13.0",
      "dependencies": []
    },
    "metadata": {
      "author": "BangoCat Team",
      "category": "Fashion",
      "tags": ["cool", "fashion", "summer"],
      "releaseDate": "2024-12-01T00:00:00Z",
      "lastUpdated": "2024-12-01T00:00:00Z"
    }
  }
]'

print_info "Creating sample plugin manifest..."

# Create the manifest file
echo "$SAMPLE_MANIFEST" > sample_manifest.json

print_success "Sample plugin manifest created: sample_manifest.json"
echo ""
print_info "This manifest includes:"
echo "  • Santa Hat (Holiday accessory)"
echo "  • Wizard Hat (Fantasy accessory)"
echo "  • Sunglasses (Fashion accessory)"
echo ""
print_info "To test the plugin system:"
echo "  1. Host this manifest at your plugin repository"
echo "  2. Create the corresponding asset files"
echo "  3. Set up license validation"
echo "  4. Update the plugin manager configuration"
echo ""
print_info "For development testing, you can:"
echo "  • Use a local server (e.g., python -m http.server 8000)"
echo "  • Place the manifest at http://localhost:8000/manifest.json"
echo "  • Update PluginRepositoryConfig.default in AccessoryPluginManager.swift"
echo ""
print_success "Sample plugin generation complete! 🎉"