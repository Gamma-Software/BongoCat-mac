# Changelog

All notable changes to BongoCat-mac will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.5] - 2025-09-30

Apple review feedback

### Modified

- Remove app sandbox entitlement
- Disable auto-start at launch by default
- Remove buy me a coffee button
- Remove macOS reference

## [1.8.4] - 2025-09-28

### Modified
- Make it really work for App Store Connect

## [1.8.3] - 2025-08-07

### Modified

- Update `push.sh` to include zipping the pkg file before upload.
- Update `run.sh` to include zipping the pkg file before upload.

## [1.8.2] - 2025-08-07

### Added

- Added `APP_APPLE_ID` to `.env.template` for Apple Developer account integration.

### Modified

- Do not push to github by default
- Updated `CHANGELOG.md` to reflect recent fixes and improvements in resource loading and packaging processes.
- Modified `Info.plist` to correct the app version and icon file path.
- Enhanced `run.sh` and `package.sh` scripts for improved build and packaging workflows, including better handling of DMG creation and App Store upload processes.

### Fixed

- Loading the images from the bundle

### Deleted

- Deleted the obsolete `analytics-config.plist.template` file to streamline project resources.

## [1.8.1] - 2025-08-06

Fix resource bundle loading issue and update environment configuration

### Fixed

- **Critical Fix**: Resolved "could not load resource bundle" error that was causing app crashes on macOS 15.6+.
- Fixed Swift Package Manager resource bundle structure in packaging script to ensure proper resource loading.
- Added proper bundle Info.plist creation for the `BongoCat-mac_BongoCat.bundle` that Swift Package Manager expects.
- Ensured all required resources (cat images, logo, menu-logo, CHANGELOG.md) are properly included in the bundle.
- Fixed resource loading fallback mechanisms to work correctly in packaged app distribution.

### Modified

- Updated `.env.template` to include new environment variables for Apple Developer account.
- Enhanced `BongoCat.entitlements` with additional security keys for improved app performance.
- Modified `run.sh` to support new build options and added verbose output for debugging.
- Updated `package.sh` to allow for flexible package creation options and improved error handling.
- Removed obsolete scripts related to code signing and packaging, streamlining the workflow.
- Improved `verify.sh` to include detailed checks for notarization status and added verbose output options.

These changes fix the critical resource loading issue and enhance the overall development and deployment process for the BongoCat application, ensuring better compliance and user experience.

## [1.8.0] - 2025-08-05

### Modified

- Bumped version in `Info.plist`, `README.md`, and `BongoCatApp.swift` to v1.8.0.
- Improved `run.sh` with a more comprehensive interactive menu for build, test, and installation options.
- Enhanced `build.sh` to support various build configurations and actions, including cleaning, testing, and installation.
- Updated `package_app.sh` to reflect the new version and streamline packaging processes.
- Removed the obsolete `clear_accessibility.sh` script to clean up the project.

## [1.7.1] - 2025-08-04

### Modified

- Update `upload_app_store.sh` to use `xcrun altool` for improved upload reliability.

## [1.7.0] - 2025-08-04

Add App Store packaging support and update README

### Modified

- Introduced functionality in `run.sh` and `package_app.sh` to build, sign, and package the app for App Store distribution.
- Updated `README.md` with instructions for App Store deployment, including requirements and usage examples.
- Introduced a new `WelcomeScreen` and `WelcomeScreenController` to guide users through initial setup.
- Updated `BongoCatApp.swift` to show the welcome screen on first launch and added menu options for accessing the welcome guide.
- Enhanced `PreferencesWindow` to keep it on top and prevent dismissal when clicking outside.

### Deleted

- Removed the obsolete `prepare_appstore.sh` script to streamline the packaging process.
- Deleted `APP_STORE_GUIDE.md` and `appstore_build.sh` as part of the cleanup.

## [1.6.0] - 2025-08-04

### Modified

- Verify that posthog api key and host are set in the .env file
- Increase app switch detection interval to 0.1 seconds and make it constant
- Rename project to BongoCat instead of BongoCat
- Change default paw behavior to alternating
- Implemented methods to retrieve, delete, and clear saved app positions.
- Updated PreferencesWindow to display saved positions with app names and provide delete functionality.
- Trigger settings update after modifying saved positions to ensure UI consistency.
- Updated `getCornerPosition` to allow specifying a screen, improving position accuracy.
- Modified `getSavedPositionsWithAppNames` to include screen names in the saved positions data structure.
- Added new methods for screen detection and management, including `getScreenNameForPosition`, `getCurrentScreenInfo`, and `moveOverlayToScreen`.
- Enhanced `PreferencesWindow` to display screen information and allow moving the overlay to different screens.
- Updated image loading logic in `BongoCatApp.swift` and `CatView.swift` to prioritize executable directory and current working directory paths for CLI execution.
- Added debug information to assist in troubleshooting image loading failures.
- Enhanced fallback mechanisms to include relative paths from the project root.

Signed-off-by: Valentin Rudloff <valentin.rudloff.perso@gmail.com>

## [1.5.6] - 2025-07-30

### Modified

- Update code_sign.sh to use notarytool for notarization
- Update run.sh to include verification steps for downloaded DMG file and installation process.

## [1.5.5] - 2025-07-30

### Modified

- Source .env file in run.sh
- Change default scale to 75%
- Per-app positioning is now enabled by default
- Per-app hiding is now enabled by default
- Auto-start is now enabled by default
- Random paw behavior is now enabled by default

## [1.5.4] - 2025-07-30

### Modified

- Open DMG file after download instead to let the user drag and drop it to the Applications folder
- Update run.sh to include verification steps for downloaded DMG file and installation process.

## [1.5.3] - 2025-07-30

### Added

- Sign the app with a certificate

### Modified

- Remove create_background.py and INSTALLATION.md files; update icon resources and references in BongoCatApp.swift to use new menu-logo.png. Add new logo assets for improved branding.

## [1.5.2] - 2025-07-28

### Modified

- Add debug methods to UpdateChecker for improved diagnostics and error handling
- Introduced `debugUpdateSystem` method to log current version, auto-update settings, and network connectivity status.
- Enhanced download task with custom URLSession configuration for better reliability and error reporting.
- Added verification steps for downloaded DMG file and installation process.
- Updated alert messages for clarity and added option to open GitHub releases on update failure.

## [1.5.1] - 2025-07-28

### Modified

- Update README and TROUBLESHOOTING documentation with accessibility permission guidance. Add clear_accessibility.sh script to assist users in managing permissions.
- Code sign app for consistent identity to prevent permission issues on reinstall. Update package_app.sh and BongoCatApp.swift for new bundle identifier and signing process.

## [1.5.0] - 2025-07-28

### Added

- **🚀 Auto-Start at Launch** - New menu option to automatically start BongoCat when you log into your Mac
  - Uses modern SMAppService API for macOS 13.0+ with fallback to legacy method
  - Automatically syncs with system login items state
  - Can be toggled on/off from the status bar menu, right-click context menu, and preferences window
  - Enabled by default for new installations
  - Respects user privacy and system permissions

## [1.4.4] - 2025-07-28

### Added

- **🚀 Auto-Start at Launch** - New menu option to automatically start BongoCat when you log into your Mac
  - Uses modern SMAppService API for macOS 13.0+ with fallback to legacy method
  - Automatically syncs with system login items state
  - Can be toggled on/off from the status bar menu, right-click context menu, and preferences window
  - Enabled by default for new installations
  - Respects user privacy and system permissions

### Modified

- Add public methods for checking updates and opening preferences in AppDelegate; update context menu in CatView to include new options
- Treat trackpad touch as left click for now
- Enhance bump_version.sh script to improve commit and tag pushing process. Updated messages for clarity and added warnings for failed tag pushes while ensuring successful commit and tag notifications are displayed.

## [1.4.3] - 2025-07-28

### Modified

- Remove unused menu items and refactor AppDelegate setup for improved clarity and performance. This includes the removal of scale options, paw behavior settings, and various notification settings from the menu structure.

### Fixed

- Flip and rotate settings now work as expected
- Refactor UpdateChecker to improve code readability by adjusting indentation in the analytics tracking switch statement for update actions.

## [1.4.2] - 2025-07-28

### Modified

- Refactor run.sh to enhance usability with command line options and improve error handling. Added a usage function and streamlined the execution of build and package commands. The interactive menu remains available for user selection.

### Removed

- Remove redundant analytics tracking for window position changes and per-app position saves in BongoCatApp and PostHogAnalyticsManager classes to streamline code and improve performance.

## [1.4.1] - 2025-07-27

### Added

- Verify setup and dependencies
- Troubleshooting guide when the cat is not animating when typing on your keyboard
- Add auto-update menu item
- Add auto-update notification

### Modified

- use utc date/time instead of sha1 in the build number
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
  - **Swift Development Guidelines** - Code style, architecture patterns, and BongoCat-specific conventions
  - **Changelog Management Rule** - Automated reminders to update changelog after development sessions
  - **Version Management Guidelines** - Semantic versioning and release process documentation
  - **Testing Guidelines** - Comprehensive testing standards and best practices
- **🔄 Update Checker** - Daily update checks for new versions, can be disabled in the menu

### Modified

- Push changelog to github release notes

## [1.1.0] -2025-07-26

### Added

- Tweet about BongoCat

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
  - "Visit Website" and "About BongoCat" menu items
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
- **Per-App Positioning**: The standout feature that sets BongoCat apart from other implementations
- **Native Performance**: Built from ground up in Swift for optimal macOS integration
- **Streaming Ready**: Perfect transparency and positioning for content creators
- **Comprehensive Customization**: Most feature-rich BongoCat implementation available

### 🚀 Future Roadmap
- Audio support with bongo sound effects
- Custom cat skins and themes
- Advanced analytics and typing statistics
- Multi-language localization
- iCloud settings sync

---

*For detailed installation instructions, usage guides, and troubleshooting, see [README.md](README.md)*