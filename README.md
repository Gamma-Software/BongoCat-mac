# Free BongoCat Overlay for macOS

<p align="center">
  <img src="media/quick.gif" alt="BongoCat Logo" width="500" />
</p>


A native macOS implementation of the beloved BongoCat overlay, written in Swift. Perfect for streamers, content creators, and anyone who wants an adorable cat companion on their desktop that reacts to their typing and interactions.

![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-blue) ![Language](https://img.shields.io/badge/Language-Swift-orange) ![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple) ![Status](https://img.shields.io/badge/Status-Stable-green) ![Version](https://img.shields.io/badge/Version-1.7.0-blue)

## What is BongoCat?

BongoCat is a popular internet meme featuring a cat playing bongos, originally created by [DitzyFlama](https://twitter.com/DitzyFlama) using [StrayRogue's](https://twitter.com/StrayRogue) adorable cat drawing. This project brings the interactive BongoCat experience to macOS as a native application.

## ✨ Features

BongoCat is a **fully-featured**, **native macOS** typing companion with extensive customization options.

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

## 🚀 Installation

### 📋 Requirements
- **macOS 13.0 (Ventura)** or later
- **Accessibility permissions** for global input monitoring
- **~5MB disk space** for the application

### 📥 Download Options

#### **🎯 Ready-to-Use (Recommended)**
1. Download the latest `BongoCat-*.dmg` from [Releases](https://github.com/Gamma-Software/BongoCat-mac/releases)
2. Open the DMG and drag BongoCat to Applications
3. **Right-click** on BongoCat in Applications and select **"Open"** (see [Gatekeeper Guide](GATEKEEPER_GUIDE.md))
4. Grant accessibility permissions when prompted

**💡 Pro Tip**: If you're reinstalling and accessibility permissions keep being asked, use the packaged DMG instead of building from source. The official releases are code signed for consistent identity.

**🔐 Security Note**: On first launch, macOS may show a security warning. This is normal for apps not signed with an Apple Developer certificate. See our [Gatekeeper Guide](GATEKEEPER_GUIDE.md) for safe launch instructions.

#### **🛠️ Build from Source**
Perfect for developers or those who want the latest features:

### Building from Source
```bash
# Clone the repository
git clone https://github.com/Gamma-Software/BongoCat-mac.git
cd BongoCat-mac

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

# Package for App Store distribution
./Scripts/package_app.sh --app_store

# Clear accessibility permissions (if having issues)
./Scripts/clear_accessibility.sh
```

### 🍎 App Store Deployment
For developers wanting to distribute BongoCat through the Mac App Store:

```bash
# Quick App Store packaging
./run.sh --app-store

# Or use the interactive menu
./run.sh
# Select option 9: "Build release, sign and package for App Store distribution"
```

**📋 Requirements**: Apple Developer Program membership, App Store distribution certificate, and App Store Connect setup. See [App Store Guide](Scripts/app_store_guide.md) for detailed instructions.

See [`Scripts/README.md`](Scripts/README.md) for detailed documentation.

## 🔧 Troubleshooting

### Common Issues
- **App won't start**: Right-click and select "Open" if you get a security warning
- **Cat not animating**: Check accessibility permissions in System Preferences
- **Position resets**: Use "Save Current Position" in the context menu

For more detailed troubleshooting, see [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

## 🤝 Development & Contributing

### 👥 **Contributing**
We welcome contributions from the community! Here's how you can help:

#### **🐛 Bug Reports**
- [Report a bug](https://github.com/Gamma-Software/BongoCat-mac/issues/new) using our issue tracker
- Include macOS version, BongoCat version, and steps to reproduce
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
BongoCat-mac/
├── Sources/BongoCat/     # Swift source code
│   ├── BongoCatApp.swift # Main app delegate & menu logic
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

## 💖 Support BongoCat

### ⭐ **Star the Project**
If you love BongoCat, please give us a star on GitHub! It helps others discover the project.

### 🐛 **Report Issues**
Found a bug? Have a suggestion? [Report a bug](https://github.com/Gamma-Software/BongoCat-mac/issues/new) - we read every one!

### 📢 **Spread the Word**
- Share BongoCat with fellow developers, streamers, and cat lovers
- Tweet about your setup with `#BongoCat`
- Write about it on your blog or social media

### 💝 **Contribute**
Whether it's code, documentation, or just ideas - every contribution makes BongoCat better!

---

<div align="center">

**Made with ❤️ by [Valentin Rudloff](https://valentin.pival.fr)**

*Bringing joy to developers, streamers, and cat lovers everywhere* 🐱

[🌐 Website](https://valentin.pival.fr) • [🐛 Report a Bug](https://github.com/Gamma-Software/BongoCat-mac/issues/new) • [📖 Documentation](Scripts/README.md) • [📦 Releases](https://github.com/Gamma-Software/BongoCat-mac/releases)

</div>
