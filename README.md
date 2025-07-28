# BangoCat-mac 🐱🥁

A native macOS implementation of the beloved BangoCat overlay, written in Swift. Perfect for streamers, content creators, and anyone who wants an adorable cat companion on their desktop that reacts to their typing and interactions.

![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-blue) ![Language](https://img.shields.io/badge/Language-Swift-orange) ![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple) ![Status](https://img.shields.io/badge/Status-Stable-green) ![Version](https://img.shields.io/badge/Version-1.5.1-blue)

## What is BangoCat?

BangoCat is a popular internet meme featuring a cat playing bongos, originally created by [DitzyFlama](https://twitter.com/DitzyFlama) using [StrayRogue's](https://twitter.com/StrayRogue) adorable cat drawing. This project brings the interactive BangoCat experience to macOS as a native application.

## ✨ Features

BangoCat is a **fully-featured**, **native macOS** typing companion with extensive customization options.

### 🐱 **Core Animation System**
- **🪟 Transparent Overlay** - Borderless, always-on-top window that works everywhere
- **⌨️ Smart Keyboard Detection** - Cat reacts to typing with intelligent paw assignments
- **🖱️ Mouse Click Animations** - Left and right click detection with paw responses
- **🎯 Consistent Key Mapping** - Same keys always use the same paw for realistic typing
- **⚡ Real-time Response** - Instant reactions to your input with smooth animations
- **🔄 State Management** - Proper paw up/down states with minimum animation durations

### 🎛️ **Extensive Customization**

#### **📏 Size & Scale Options**
- **Multiple Scale Presets**: Small (65%), Medium (75%), Big (100%)
- **Scale Pulse Animation**: Optional size pulse on each keystroke/click
- **Dynamic Scaling**: Window resizes automatically with scale changes

#### **🎨 Visual Customization**
- **Cat Rotation**: Toggle 13° tilt (adjusts automatically with flip direction)
- **Horizontal Flip**: Mirror the cat for left-handed setups or preference
- **Position Memory**: Remembers your preferred placement

#### **🎯 Advanced Positioning**
- **Drag & Drop**: Move the cat anywhere on screen by dragging
- **Corner Snapping**: Quick positioning to screen corners (Top/Bottom × Left/Right)
- **Per-App Positioning**: 🌟 **Unique Feature!** Cat remembers different positions for different applications
- **Position Persistence**: Saves and restores positions across app restarts
- **Multi-Monitor Support**: Works across multiple displays

### 📊 **Analytics & Tracking**
- **📈 Comprehensive Stroke Counter**: Tracks total keystrokes and mouse clicks separately
- **💾 Persistent Statistics**: Counters survive app restarts
- **🔄 Counter Reset**: Easy reset functionality when needed
- **📱 Menu Display**: Current stats always visible in status bar menu

### 🎮 **Input Modes & Control**
- **⌨️ Full Keyboard Support**: Detects all key presses and releases
- **🖱️ Mouse Integration**: Left and right click detection
- **🚫 Ignore Clicks Mode**: Disable mouse click reactions when needed
- **🔇 Input Filtering**: Smart handling of key repeats and held keys

### 🖥️ **System Integration**

#### **📋 Status Bar Menu**
- **🎛️ Complete Settings Access**: All features accessible from menu bar
- **📊 Live Statistics**: Real-time stroke counter display
- **⚙️ Quick Toggles**: Enable/disable features with single clicks
- **ℹ️ Version Information**: Built-in version display and about dialog

#### **🖱️ Context Menu**
- **Right-click Anywhere**: Full feature access directly on the cat
- **🚀 Quick Actions**: Scale, position, flip, and more
- **📍 Position Shortcuts**: Instant corner positioning

#### **🍎 macOS Native Integration**
- **🔒 Accessibility Permissions**: Proper system permission handling
- **🖥️ Multi-Space Support**: Works across all desktop spaces and full-screen apps
- **⚡ Low Resource Usage**: Optimized native Swift implementation
- **📺 Streaming Ready**: Perfect transparency for OBS, Streamlabs, etc.

### 🛠️ **Developer Features**
- **📦 Swift Package Manager**: Modern dependency management
- **🔨 Build Scripts**: Automated build and packaging tools
- **🏷️ Version Management**: Comprehensive version bump automation
- **📖 Documentation**: Extensive documentation and examples
- **🧪 Extensible Architecture**: Clean, modular Swift/SwiftUI codebase

### 🎯 **Streaming & Content Creation**
- **🎥 OBS Integration**: Add as Window Capture source with transparency
- **📱 Always Visible**: Stays on top of all applications
- **🎨 Clean Transparency**: Perfect for overlaying on content
- **📏 Scalable Display**: Adjust size for different streaming layouts
- **🎮 Gaming Compatible**: Works with full-screen games and applications

### 🌟 **Unique BangoCat Features**

#### **🎯 Per-Application Positioning**
The **standout feature** that sets BangoCat apart:
- **📱 App-Specific Memory**: Cat remembers different positions for each application
- **🔄 Automatic Switching**: Instantly moves to the right spot when you switch apps
- **💡 Smart Detection**: Uses bundle identifiers for reliable app recognition
- **⚙️ Easy Toggle**: Enable/disable per-app positioning as needed

#### **🧠 Intelligent Input Handling**
- **🎯 Consistent Paw Assignment**: Same keys always trigger same paws
- **⏱️ Timing Intelligence**: Proper animation durations and state management
- **🔄 State Persistence**: Remembers settings and positions across sessions
- **🚫 Smart Filtering**: Handles key repeats and system events gracefully

### 🎮 **Perfect For**
- **🎥 Streamers & Content Creators** - Engaging overlay for audiences
- **💻 Developers & Writers** - Motivating typing companion
- **🎮 Gamers** - Fun addition to gaming streams
- **📚 Students** - Makes typing practice more enjoyable
- **🐱 Cat Lovers** - Adorable desktop companion

## 📊 Analytics Setup (Optional)

BangoCat includes **optional PostHog analytics** to help improve the app with anonymous usage data. **Your privacy is protected** - no personal information is collected.

### 🔒 **Secure Configuration**
Since this is a public repository, **API keys are never committed**. Choose your preferred setup method:

#### **🌍 Environment Variables (Recommended)**
```bash
export POSTHOG_API_KEY="ph_your_key_here"
export POSTHOG_HOST="https://us.i.posthog.com"
```

#### **📁 Local Config File**
```bash
cp analytics-config.plist.template analytics-config.plist
# Edit analytics-config.plist with your keys
```

#### **🔧 For Developers**
See [`ANALYTICS_SETUP.md`](ANALYTICS_SETUP.md) for detailed setup instructions, including:
- How to create a free PostHog account
- Configuration methods for different environments
- Privacy controls and what data is tracked
- Testing and troubleshooting guides

### 🔒 **Privacy First**
- **✅ Anonymous tracking** - No personal identification
- **✅ User opt-out** - Easy disable via menu
- **✅ Transparent** - Clear explanation of what's tracked
- **✅ Optional** - App works perfectly without analytics

## 🚀 Installation

### 📋 Requirements
- **macOS 13.0 (Ventura)** or later
- **Accessibility permissions** for global input monitoring
- **~5MB disk space** for the application

### 📥 Download Options

#### **🎯 Ready-to-Use (Recommended)**
1. Download the latest `BangoCat-*.dmg` from [Releases](https://github.com/Gamma-Software/BangoCat-mac/releases)
2. Open the DMG and drag BangoCat to Applications
3. Launch BangoCat from Applications or Spotlight
4. Grant accessibility permissions when prompted

**💡 Pro Tip**: If you're reinstalling and accessibility permissions keep being asked, use the packaged DMG instead of building from source. The official releases are code signed for consistent identity.

#### **🛠️ Build from Source**
Perfect for developers or those who want the latest features:

### Building from Source
```bash
# Clone the repository
git clone https://github.com/Gamma-Software/BangoCat-mac.git
cd BangoCat-mac

# Quick build and test
./Scripts/build.sh
swift run

# Or build manually
swift build
swift run
```

### Development Scripts
The project includes helpful scripts in the `Scripts/` directory:

```bash
# Build the project
./Scripts/build.sh

# Bump version (updates all version references)
./Scripts/bump_version.sh 1.0.2

# Create distributable DMG
./Scripts/package_app.sh

# Clear accessibility permissions (if having issues)
./Scripts/clear_accessibility.sh
```

See [`Scripts/README.md`](Scripts/README.md) for detailed documentation.

## 🔧 Troubleshooting

### Accessibility Permission Issues
If you're having trouble with accessibility permissions after reinstalling:

1. **Use the official DMG**: Download from [Releases](https://github.com/Gamma-Software/BangoCat-mac/releases) instead of building from source
2. **Clear old permissions**: Run `./Scripts/clear_accessibility.sh` to open System Preferences
3. **Remove from Accessibility list**: In System Preferences → Security & Privacy → Accessibility, remove BangoCat if it's there
4. **Reinstall and grant permissions**: Launch BangoCat again and grant permissions when prompted

### Common Issues
- **App won't start**: Right-click and select "Open" if you get a security warning
- **Cat not animating**: Check accessibility permissions in System Preferences
- **Position resets**: Use "Save Current Position" in the context menu

For more detailed troubleshooting, see [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

## 🤝 Development & Contributing

### 👥 **Contributing**
We welcome contributions from the community! Here's how you can help:

#### **🐛 Bug Reports**
- [Report a bug](https://github.com/Gamma-Software/BangoCat-mac/issues/new) using our issue tracker
- Include macOS version, BangoCat version, and steps to reproduce
- Screenshots/screen recordings are super helpful

#### **💡 Feature Requests**
- Open an issue with the `enhancement` label
- Describe the use case and expected behavior
- Check existing issues to avoid duplicates

#### **🔧 Code Contributions**
- Fork the repository and create a feature branch
- Follow Swift conventions and include tests where applicable
- Update documentation for new features
- Submit a pull request with a clear description

#### **📚 Documentation**
- Improve README, code comments, or script documentation
- Create tutorials or setup guides
- Translate documentation to other languages

### Project Structure
```
BangoCat-mac/
├── Sources/BangoCat/     # Swift source code
│   ├── BangoCatApp.swift # Main app delegate & menu logic
│   ├── OverlayWindow.swift # Overlay window management
│   ├── CatView.swift     # SwiftUI cat view & animations
│   ├── InputMonitor.swift # Global input monitoring
│   └── Resources/        # Embedded app resources
├── Assets/               # Project assets
│   ├── Icons/           # App icons (.icns, .ico files)
│   └── Images/          # Cat sprite images
├── Scripts/              # Build & development scripts
│   ├── build.sh         # Quick build script
│   ├── package_app.sh   # Create distributable DMG
│   ├── bump_version.sh  # Version management
│   └── README.md        # Script documentation
├── Build/                # Build outputs (gitignored)
│   ├── package/         # App bundle staging
│   └── *.dmg           # Distributable packages
├── Tests/                # Unit tests
├── Package.swift         # Swift Package Manager config
├── Info.plist           # macOS app bundle metadata
└── README.md            # This file
```

### 🛠️ **Technical Details**
- **Framework**: SwiftUI + AppKit hybrid architecture
- **Global Events**: CGEvent APIs for system-wide input monitoring
- **Language**: Swift 5.9+ with modern concurrency support
- **Architecture**: MVVM pattern with reactive UI updates
- **Minimum Target**: macOS 13.0 (Ventura) for latest SwiftUI features
- **Build System**: Swift Package Manager for dependency management

### Tested on

The app was tested on my MacBook Pro 14 inch M2 Max (2023) with macOS 15.5

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits & Acknowledgments

### 🎨 **Original Creators**
- **🐱 Bongo Cat Meme**: Created by [@DitzyFlama](https://twitter.com/DitzyFlama)
- **🎨 Cat Artwork**: Original cat drawing by [@StrayRogue](https://twitter.com/StrayRogue)
- **🎮 Windows Version**: Inspiration from Irox Games Studio's Steam version

### 💻 **Technical Inspiration**
- **Python Implementation**: [mac-typing-bongo-cat](https://github.com/111116/mac-typing-bongo-cat) for initial concept
- **Swift Community**: For excellent documentation and examples
- **macOS Developer Community**: For accessibility and window management patterns

### 🤝 **Special Thanks**
- All beta testers and early adopters
- Contributors who provided feedback and suggestions
- The streaming community for feature requests
- Swift/SwiftUI community for technical guidance

---

## 💖 Support BangoCat

### ⭐ **Star the Project**
If you love BangoCat, please give us a star on GitHub! It helps others discover the project.

### 🐛 **Report Issues**
Found a bug? Have a suggestion? [Report a bug](https://github.com/Gamma-Software/BangoCat-mac/issues/new) - we read every one!

### 📢 **Spread the Word**
- Share BangoCat with fellow developers, streamers, and cat lovers
- Tweet about your setup with `#BangoCat`
- Write about it on your blog or social media

### 💝 **Contribute**
Whether it's code, documentation, or just ideas - every contribution makes BangoCat better!

---

<div align="center">

**Made with ❤️ by [Valentin Rudloff](https://valentin.pival.fr)**

*Bringing joy to developers, streamers, and cat lovers everywhere* 🐱

[🌐 Website](https://valentin.pival.fr) • [🐛 Report a Bug](https://github.com/Gamma-Software/BangoCat-mac/issues/new) • [📖 Documentation](Scripts/README.md) • [📦 Releases](https://github.com/Gamma-Software/BangoCat-mac/releases)

</div>
