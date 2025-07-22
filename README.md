# BangoCat-mac 🐱🥁

A native macOS implementation of the beloved BangoCat overlay, written in Swift. Perfect for streamers, content creators, and anyone who wants an adorable cat companion on their desktop that reacts to their typing and interactions.

![BangoCat Demo](https://img.shields.io/badge/Status-In%20Development-yellow) ![Platform](https://img.shields.io/badge/Platform-macOS-blue) ![Language](https://img.shields.io/badge/Language-Swift-orange)

## What is BangoCat?

BangoCat is a popular internet meme featuring a cat playing bongos, originally created by [DitzyFlama](https://twitter.com/DitzyFlama) using [StrayRogue's](https://twitter.com/StrayRogue) adorable cat drawing. This project brings the interactive BangoCat experience to macOS as a native application.

## Features

### ✅ Planned Features
- 🪟 **Transparent overlay window** - Borderless, always-on-top display
- ⌨️ **Global keyboard detection** - Cat reacts to your typing in any application
- 🎮 **Multiple input modes** - Support for keyboard, mouse, and game controllers
- 🎨 **Smooth animations** - Fluid sprite-based cat animations
- 📺 **Streaming-ready** - Perfect for OBS, Streamlabs, and other streaming software
- 🎯 **Customizable positioning** - Place your cat anywhere on screen
- 🔧 **Configurable settings** - Adjust sensitivity, animation speed, and more
- 🎵 **Audio feedback** - Optional bongo sounds (can be muted)
- 💾 **Low resource usage** - Optimized native Swift implementation

### 🚧 Current Status
This project is in early development. Check back soon for updates!

## Installation

### Requirements
- macOS 11.0 (Big Sur) or later
- Accessibility permissions for global keyboard monitoring

### Download
*Coming soon - releases will be available on GitHub*

### Building from Source
```bash
# Clone the repository
git clone https://github.com/your-username/BangoCat-mac.git
cd BangoCat-mac

# Open in Xcode
open BangoCat-mac.xcodeproj

# Build and run (⌘+R)
```

## Usage

1. **Launch the app** - BangoCat will appear as a small overlay on your screen
2. **Grant permissions** - Allow accessibility access when prompted
3. **Position your cat** - Drag to move the overlay anywhere on screen
4. **Start typing** - Watch your cat react to keypresses!
5. **Use with OBS** - Add as a Window Capture source for streaming

### Streaming Setup (OBS)
1. Add a new **Window Capture** source
2. Select "BangoCat-mac" from the window list
3. Enable **Allow Transparency** in the source properties
4. Position and resize as needed

## Why Choose BangoCat-mac?

### Compared to Existing Solutions

| Feature | BangoCat-mac (Swift) | [mac-typing-bongo-cat](https://github.com/111116/mac-typing-bongo-cat) (Python) |
|---------|---------------------|---------------------------------------------------------------------------------|
| Performance | ⚡ Native, optimized | 🐌 Requires Python runtime |
| Dependencies | ✅ None | ❌ Requires pyobjc packages |
| Stability | ✅ Native macOS APIs | ⚠️ Known compatibility issues |
| Memory Usage | ✅ Low | ❌ Higher overhead |
| App Store Ready | ✅ Potentially | ❌ No |
| Permissions | ✅ Standard macOS prompts | ❌ Often requires sudo |

## Development

### Contributing
Contributions are welcome! Please feel free to:
- Report bugs and issues
- Suggest new features
- Submit pull requests
- Improve documentation

### Project Structure
```
BangoCat-mac/
├── Sources/
│   ├── App/           # Main application logic
│   ├── Overlay/       # Overlay window management
│   ├── Input/         # Global input monitoring
│   ├── Animation/     # Cat sprite animations
│   └── Assets/        # Cat images and sounds
├── Resources/         # App icons and metadata
└── Tests/            # Unit tests
```

### Technical Details
- **Framework**: SwiftUI + AppKit
- **Global Events**: CGEvent APIs for system-wide input monitoring
- **Window Management**: NSWindow with transparent, topmost properties
- **Animation**: Core Animation for smooth sprite transitions

## Credits & Attribution

- **Original Cat Art**: [StrayRogue](https://twitter.com/StrayRogue)
- **BangoCat Meme**: [DitzyFlama](https://twitter.com/DitzyFlama)
- **Original Web Version**: [bongo.cat](https://bongo.cat) by [Externalizable](https://github.com/Externalizable)
- **Inspiration**: Various BangoCat implementations across platforms

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The original BangoCat artwork is used with permission and credited to the original creators.

## Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/your-username/BangoCat-mac/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/your-username/BangoCat-mac/discussions)
- 📧 **Contact**: [Your contact information]

---

*Made with ❤️ for the macOS community*

**Disclaimer**: This is an unofficial implementation. BangoCat-mac is not affiliated with the original BangoCat creators, though we greatly appreciate their wonderful work that inspired this project.
