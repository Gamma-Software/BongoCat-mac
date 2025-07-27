# Changelog

All notable changes to BangoCat-mac will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased] - 2025-07-27

### Added

- Verify setup and dependencies
- Troubleshooting guide when the cat is not animating when typing on your keyboard
- Add auto-update menu item
- Add auto-update notification

### Modified

- Make sure to source variables from the .env file when building the prod app
- Add --push and --commit options to bump_version.sh script
- Update run.sh to include additional options for building and bumping release versions; enhance build.sh to clean previous artifacts; refactor UpdateChecker for improved error handling and analytics tracking.

### Fixed

- install_local instead of local_install
- Incompatible change: Update notification system to use UserNotifications framework

## [1.4.0] - 2025-07-27

### Added

- Run script to build and package the app more easily

### Modified

- Remove text artifacts from changelog release notes
- Download DMG from GitHub releases for auto-update
- Remove scroll wheel detection logs

## [1.3.0] - 2025-07-27

### Added

- **🔄 PostHog Analytics** - Anonymous analytics for feature usage and app behavior

### Modified

- Commit when bumping version with the script
- Remove trackpad touch detection

## [1.2.0] - 2025-07-26

### Added

- **📋 Cursor Rules System** - Comprehensive development rules and guidelines for consistent code quality
  - **Project Context Rule** - Always-applied project structure and development guidelines
  - **Swift Development Guidelines** - Code style, architecture patterns, and BangoCat-specific conventions
  - **Changelog Management Rule** - Automated reminders to update changelog after development sessions
  - **Version Management Guidelines** - Semantic versioning and release process documentation
  - **Testing Guidelines** - Comprehensive testing standards and best practices
- **🔄 Update Checker** - Daily update checks for new versions, can be disabled in the menu

### Modified

- Push changelog to github release notes

## [1.1.0] -2025-07-26

### Added

- Tweet about BangoCat

## [1.0.0] - 2025-07-26

### Added
- **🎯 Keyboard Layout-Based Paw Mapping** - Intelligent paw assignment based on physical keyboard layout for realistic typing animations
- **🐛 Enhanced Bug Reporting** - Improved error reporting and debugging features
- **📱 Per-App Positioning** - Revolutionary feature that remembers different cat positions for each application
- **📊 Comprehensive Stroke Counter** - Tracks keystrokes and mouse clicks with persistent statistics
- **🎨 Visual Customization System**:
  - Multiple scale presets (Small 65%, Medium 75%, Big 100%)
  - Scale pulse animation on keystroke/click
  - Cat rotation (13° tilt) with smart direction adjustment
  - Horizontal flip for left-handed users or preferences
- **🎯 Keyboard Layout-Based Paw Mapping** - Intelligent paw assignment based on physical keyboard layout for realistic typing animations
- **🐛 Enhanced Bug Reporting** - Improved error reporting and debugging features
- **📱 Per-App Positioning** - Revolutionary feature that remembers different cat positions for each application
- **📊 Comprehensive Stroke Counter** - Tracks keystrokes and mouse clicks with persistent statistics
- **🎨 Visual Customization System**:
  - Multiple scale presets (Small 65%, Medium 75%, Big 100%)
  - Scale pulse animation on keystroke/click
  - Cat rotation (13° tilt) with smart direction adjustment
  - Horizontal flip for left-handed users or preferences
- **📍 Advanced Positioning Features**:
  - Drag & drop positioning anywhere on screen
  - Corner snapping (Top/Bottom × Left/Right combinations)
  - Position memory across app restarts
  - Multi-monitor support
- **🎛️ Complete Menu System**:
  - Status bar menu with all settings
  - Right-click context menu on cat overlay
  - "Visit Website" and "About BangoCat" menu items
- **🚫 Input Control Options**:
  - Ignore clicks mode to disable mouse reactions
  - Smart input filtering for key repeats
- **🔄 Factory Reset** - Reset all settings to defaults functionality
- **🖱️ Mouse Integration** - Left and right click detection with paw responses
- **🎮 System Integration**:
  - Proper accessibility permissions handling
  - Always-on-top overlay window
  - Multi-space and full-screen app support
- **📦 Distribution & Packaging**:
  - Professional DMG creation with custom background
  - App icon integration (.icns format)
  - Automated build and packaging scripts
- **🐱 Core Animation System**:
  - Transparent borderless overlay window
  - Real-time input response with smooth animations
  - Proper paw up/down state management
  - Consistent key-to-paw mapping
- **🎨 Sprite System** - Complete cat sprite images (base, left/right paw up/down states)

### Technical Improvements
- **🏗️ Project Structure Refactoring** - Organized codebase with proper Swift/SwiftUI architecture
- **📝 Version Management** - Automated version bumping across Info.plist and source files
- **🔧 Build System** - Comprehensive build scripts and Swift Package Manager integration
- **🧪 Testing Infrastructure** - Unit tests for core functionality
- **📚 Documentation** - Extensive README with features, installation, and usage instructions
- **🗂️ Resource Management** - Optimized image loading with fallback mechanisms
- **💾 Settings Persistence** - Proper storage and retrieval of user preferences
- **🖥️ Window Management** - Advanced overlay window handling with transparency support
- **⚡ Performance Optimization** - Efficient input monitoring and animation rendering

### Development Features
- **🛠️ Developer Scripts**:
  - `build.sh` - Quick build and test script
  - `package_app.sh` - Create distributable DMG packages
  - `bump_version.sh` - Automated version management
  - `test.sh` - Run unit tests
- **📖 Script Documentation** - Comprehensive documentation in Scripts/README.md
- **🏷️ Version Tracking** - Current version 1.0.0 (build 2025.07)
- **🔍 Enhanced Debugging** - Improved error handling and logging

### Fixed
- **🖼️ Image Loading** - Robust sprite loading with proper error handling
- **📍 Position Management** - Reliable position saving and restoration
- **🔄 State Management** - Proper handling of app switching and window focus
- **🎨 UI Responsiveness** - Smooth animations and consistent visual states
- **⚙️ Settings Synchronization** - Reliable preference storage and retrieval

### Infrastructure
- **📦 Swift Package Manager** - Modern dependency management
- **🍎 macOS Native Integration** - Proper Cocoa and SwiftUI implementation
- **🎯 Accessibility Compliance** - Standard macOS accessibility permission handling
- **🔒 Security** - Proper sandboxing and permission management
- **📱 Compatibility** - Support for macOS 13.0 (Ventura) and later

## [Initial Development] - 2025-01-18 to 2025-01-20

### Development Timeline
- **Day 1 (Jan 18)**: Initial commit and project foundation
- **Day 1-2**: Core sprite system implementation
- **Day 2 (Jan 19)**: Major feature development burst:
  - Input handling and animation logic
  - Scale management and UI responsiveness
  - Position management features
  - Status bar integration
  - Advanced customization options
- **Day 2-3**: Polish and enhancement phase:
  - Menu system implementation
  - Professional packaging
  - Documentation and README
  - Bug fixes and optimizations
- **Day 3 (Jan 20)**: Final features and release preparation:
  - Per-app positioning (flagship feature)
  - Bug reporting enhancements
  - Keyboard layout-based paw mapping

### Architecture Evolution
1. **Foundation Phase**: Basic Swift project structure and sprite system
2. **Core Features Phase**: Input monitoring, animations, and basic customization
3. **Advanced Features Phase**: Position management, menus, and user experience
4. **Polish Phase**: Professional packaging, documentation, and final optimizations
5. **Innovation Phase**: Per-app positioning and intelligent paw mapping

---

## Versioning Strategy

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes

## Release Notes

### 🎯 Key Features Highlighted
- **Per-App Positioning**: The standout feature that sets BangoCat apart from other implementations
- **Native Performance**: Built from ground up in Swift for optimal macOS integration
- **Streaming Ready**: Perfect transparency and positioning for content creators
- **Comprehensive Customization**: Most feature-rich BangoCat implementation available

### 🚀 Future Roadmap
- Audio support with bongo sound effects
- Custom cat skins and themes
- Advanced analytics and typing statistics
- Multi-language localization
- iCloud settings sync

---

*For detailed installation instructions, usage guides, and troubleshooting, see [README.md](README.md)*