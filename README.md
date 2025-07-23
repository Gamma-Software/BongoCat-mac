# BangoCat-mac 🐱🥁

A native macOS implementation of the beloved BangoCat overlay, written in Swift. Perfect for streamers, content creators, and anyone who wants an adorable cat companion on their desktop that reacts to their typing and interactions.

![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-blue) ![Language](https://img.shields.io/badge/Language-Swift-orange) ![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple) ![Status](https://img.shields.io/badge/Status-Stable-green) ![Version](https://img.shields.io/badge/Version-1.0.1-blue)

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

## 🚀 Installation

### 📋 Requirements
- **macOS 13.0 (Ventura)** or later
- **Accessibility permissions** for global input monitoring
- **~5MB disk space** for the application

### 📥 Download Options

#### **🎯 Ready-to-Use (Recommended)**
1. Download the latest `BangoCat-*.dmg` from [Releases](https://github.com/your-username/BangoCat-mac/releases)
2. Open the DMG and drag BangoCat to Applications
3. Launch BangoCat from Applications or Spotlight
4. Grant accessibility permissions when prompted

#### **🛠️ Build from Source**
Perfect for developers or those who want the latest features:

### Building from Source
```bash
# Clone the repository
git clone https://github.com/your-username/BangoCat-mac.git
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
```

See [`Scripts/README.md`](Scripts/README.md) for detailed documentation.

## 🎮 Usage

### 🚀 **Quick Start**
1. **🖱️ Launch BangoCat** - App appears as a small overlay + status bar icon
2. **🔒 Grant Permissions** - Allow accessibility access when prompted (required for input detection)
3. **🎯 Position Your Cat** - Drag anywhere on screen or use corner positioning
4. **⌨️ Start Typing** - Watch your cat react to every keystroke and click!
5. **⚙️ Customize** - Right-click the cat or use the status bar menu for settings

### 🎛️ **Feature Access**

#### **📋 Status Bar Menu** (Click the cat icon in menu bar)
- **🎚️ Scale Options**: Small/Medium/Big presets
- **✨ Visual Effects**: Scale pulse, rotation, horizontal flip
- **📍 Position Control**: Corner positioning, per-app positioning toggle
- **🚫 Input Modes**: Ignore clicks, scale pulse control
- **📊 Statistics**: Live stroke counter, reset option
- **ℹ️ Information**: About dialog, version info, website link

#### **🖱️ Right-Click Context Menu** (Right-click anywhere on the cat)
- **📏 Quick Scale**: Instant size adjustments
- **🔄 Flip & Rotate**: Visual customization options
- **📍 Position Shortcuts**: Move to corners instantly
- **⚙️ Settings Toggle**: All major features accessible
- **🎮 Utility Actions**: Hide, reset counter, quit

### 🌟 **Advanced Features**

#### **🎯 Per-App Positioning Setup**
1. **Enable**: Status Bar Menu → Position → Per-App Positioning ✓
2. **Position**: Move cat to desired location in each app
3. **Automatic**: Cat remembers and moves automatically when switching apps
4. **Example Setup**:
   - **Xcode**: Bottom-right corner (out of code area)
   - **Safari**: Top-left corner (doesn't block content)
   - **Terminal**: Bottom-left corner (visible but not intrusive)

#### **📊 Stroke Counter**
- **📈 Tracking**: Automatically counts keystrokes and mouse clicks
- **💾 Persistence**: Survives app restarts and system reboots
- **📱 Display**: Always visible in status bar menu
- **🔄 Reset**: Easy reset when starting new projects

#### **🎨 Visual Customization**
- **📏 Scaling**: 65%, 75%, 100% presets with smooth animations
- **✨ Pulse Effect**: Cat briefly scales up on each input (toggle on/off)
- **🔄 Rotation**: 13° tilt that adjusts direction when flipped
- **🪞 Horizontal Flip**: Perfect for left-handed users or preference

### 📺 **Streaming & OBS Setup**

#### **🎥 OBS Studio Integration**
1. **➕ Add Source**: Sources → Add → Window Capture
2. **🖥️ Select Window**: Choose "BangoCat" from dropdown
3. **🎨 Enable Transparency**: Check "Allow Transparency" in properties
4. **📏 Position & Scale**: Resize and position as needed for your layout
5. **✨ Pro Tip**: Use per-app positioning to keep cat in perfect streaming position

#### **🎮 Gaming & Full-Screen Apps**
- **🖥️ Always On Top**: Cat stays visible even in full-screen games
- **🎯 Multi-Space Support**: Works across all desktop spaces and Mission Control
- **⚡ Low Impact**: Minimal performance impact during gaming
- **🎨 Transparent**: Won't interfere with game visuals

### 🔧 **Troubleshooting**

#### **🚫 Cat Not Responding to Input**
1. **Check Permissions**: System Preferences → Security & Privacy → Accessibility
2. **Add BangoCat**: Ensure BangoCat is listed and enabled
3. **Restart App**: Quit and relaunch BangoCat
4. **System Restart**: Reboot if permissions seem stuck

#### **📍 Position Issues**
- **Per-App Mode**: Try toggling per-app positioning off/on
- **Reset Position**: Use corner positioning to reset to known locations
- **Manual Override**: Drag cat to new position to override saved locations

#### **🎨 Streaming Issues**
- **OBS Transparency**: Ensure "Allow Transparency" is enabled in source properties
- **Window Selection**: Make sure you're capturing the correct BangoCat window
- **Performance**: Try disabling scale pulse for smoother streaming performance

## 🌟 Why Choose BangoCat-mac?

### 🎯 **The Complete BangoCat Experience**

This isn't just another typing cat app – it's the **most comprehensive and polished** BangoCat implementation available for macOS.

### 🚀 **Native Performance & Integration**
- **⚡ Swift-Native**: Built from the ground up in Swift/SwiftUI for optimal performance
- **🧠 Smart Memory Usage**: Minimal RAM footprint (~10-15MB typical usage)
- **🔋 Energy Efficient**: Optimized for laptop battery life
- **🍎 macOS Native**: Uses proper Cocoa APIs and design patterns
- **🎯 No Dependencies**: Zero external runtime requirements

### 🌈 **Feature-Rich Beyond Alternatives**

| **Feature** | **BangoCat-mac** | **Other Solutions** |
|-------------|------------------|-------------------|
| **Per-App Positioning** | ✅ **Unique Feature** | ❌ Not available |
| **Comprehensive Stroke Counter** | ✅ Full statistics | ⚠️ Basic or none |
| **Visual Customization** | ✅ Scale, rotate, flip, pulse | ⚠️ Limited options |
| **Menu Integration** | ✅ Full status bar + context menus | ❌ Minimal UI |
| **Streaming Ready** | ✅ Perfect OBS transparency | ⚠️ Basic overlay |
| **Smart Input Handling** | ✅ Consistent paw mapping | ❌ Random assignment |
| **Position Memory** | ✅ Persistent across restarts | ❌ Resets each launch |
| **Developer Experience** | ✅ Modern Swift tooling | ⚠️ Python/legacy tools |

### 🔒 **Professional Reliability**
- **🛡️ Proper Permissions**: Standard macOS accessibility requests (no sudo required)
- **💾 Data Persistence**: All settings and statistics survive app restarts
- **🔄 Automatic Recovery**: Handles system events and app switching gracefully
- **🧪 Tested & Stable**: Thoroughly tested across different macOS versions
- **📚 Well Documented**: Comprehensive documentation and troubleshooting guides

### 🎨 **Streaming & Content Creator Focused**
- **📺 OBS Perfect**: Designed specifically for streaming workflows
- **🎮 Gaming Compatible**: Works flawlessly with full-screen games
- **🖥️ Multi-Monitor**: Proper support for complex display setups
- **⚡ Performance Optimized**: Won't impact your stream performance
- **🎯 Professional Features**: Per-app positioning for consistent streaming layouts

## 🚀 Roadmap & Future Enhancements

### 🎯 **Planned Features**
- **🎵 Audio Support**: Optional bongo sound effects with volume control
- **🎨 Custom Cat Skins**: Additional cat designs and color themes
- **📊 Advanced Analytics**: Detailed typing statistics and WPM tracking
- **🎮 Game Controller Support**: Xbox/PlayStation controller input detection
- **🌍 Multi-Language**: Localization for international users
- **☁️ Settings Sync**: iCloud sync for settings across multiple Macs

### 💡 **Community Ideas**
Have a feature request? We'd love to hear it! Open an issue with the `enhancement` label.

## 🤝 Development & Contributing

### 👥 **Contributing**
We welcome contributions from the community! Here's how you can help:

#### **🐛 Bug Reports**
- Use the issue tracker for bug reports
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
Found a bug? Have a suggestion? [Open an issue](https://github.com/your-username/BangoCat-mac/issues) - we read every one!

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

[🌐 Website](https://valentin.pival.fr) • [🐛 Issues](https://github.com/your-username/BangoCat-mac/issues) • [📖 Documentation](Scripts/README.md) • [📦 Releases](https://github.com/your-username/BangoCat-mac/releases)

</div>


