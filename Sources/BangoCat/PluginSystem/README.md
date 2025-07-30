# BangoCat Plugin System

This directory contains the implementation of the BangoCat accessory plugin system, which allows users to purchase and download additional accessories for their cat.

## Architecture Overview

### Core Components

1. **AccessoryPlugin.swift** - Core protocol and data structures
2. **AccessoryPluginManager.swift** - Plugin discovery, download, and state management
3. **AccessoryPluginRenderer.swift** - Rendering accessories on the cat sprite
4. **AccessoryStoreView.swift** - User interface for browsing and purchasing plugins
5. **PluginIntegration.swift** - Integration with existing app components
6. **PluginRepositoryServer.swift** - Server-side configuration documentation

### Plugin System Flow

```
User opens Accessory Store
    ↓
Fetch plugin manifest from server
    ↓
Display available plugins
    ↓
User purchases plugin with license key
    ↓
Validate license with server
    ↓
Download plugin assets
    ↓
Enable plugin for use
    ↓
Render accessories on cat
```

## Security Features

### License Validation
- Server-side license validation
- Device ID tracking to prevent sharing
- License expiration management
- Rate limiting to prevent abuse

### Asset Protection
- Assets only served to authenticated requests
- License-based access control
- Device limit enforcement
- Secure download URLs with expiration

## Plugin Development

### Plugin Manifest Structure

```json
{
  "id": "plugin-id",
  "name": "Plugin Name",
  "description": "Plugin description",
  "version": "1.0.0",
  "price": 2.99,
  "assets": [
    {
      "name": "Asset Name",
      "filename": "asset.png",
      "position": {"x": 0, "y": -20},
      "scale": 1.0,
      "zIndex": 10,
      "tintColor": "#FF0000"
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
    "author": "Plugin Author",
    "category": "Category",
    "tags": ["tag1", "tag2"],
    "releaseDate": "2024-12-01T00:00:00Z",
    "lastUpdated": "2024-12-01T00:00:00Z"
  }
}
```

### Asset Requirements

- **Format**: PNG with transparency
- **Size**: Recommended 150x150px for accessories
- **Naming**: Use descriptive names (e.g., `santa-hat.png`)
- **Positioning**: Assets are positioned relative to the cat sprite
- **Z-Index**: Higher numbers render on top

### Positioning System

The positioning system allows precise placement of accessories:

- **anchorPoint**: Relative position on the cat (0,0 = top-left, 1,1 = bottom-right)
- **offset**: Additional pixel offset from anchor point
- **rotationOffset**: Rotation in degrees
- **scaleWithCat**: Whether accessory scales with cat size

## Server Setup

### Requirements

1. **Web Server**: Node.js/Express, Python/Flask, or similar
2. **SSL Certificate**: HTTPS required for production
3. **Database**: For license management (optional)
4. **CDN**: For asset delivery (recommended)

### API Endpoints

#### GET /manifest.json
Returns the public plugin catalog (no authentication required)

#### GET /assets/{pluginId}/{filename}
Protected endpoint for downloading plugin assets
- Requires valid license for the specific plugin
- Returns 403 if license is invalid or expired

#### POST /validate
License validation endpoint
- Validates license keys
- Tracks device usage
- Returns validation status

### Security Implementation

```javascript
// Example Node.js/Express implementation
app.get('/assets/:pluginId/:filename', (req, res) => {
  const { pluginId, filename } = req.params;
  const licenseKey = req.headers.authorization?.replace('Bearer ', '');

  if (!validateLicense(licenseKey, pluginId)) {
    return res.status(403).send('Invalid license');
  }

  const assetPath = `./assets/${pluginId}/${filename}`;
  res.sendFile(assetPath);
});
```

## Client Integration

### Plugin Manager

The `AccessoryPluginManager` handles:

- Plugin discovery and manifest fetching
- License validation and purchase flow
- Asset downloading and caching
- Plugin state management (enabled/disabled)
- Persistence of plugin preferences

### Rendering System

The `AccessoryPluginRenderer` handles:

- Loading plugin assets
- Applying transformations (scale, rotation, flip)
- Z-index management for proper layering
- Animation integration with cat states

### User Interface

The `AccessoryStoreView` provides:

- Grid-based plugin browsing
- Purchase dialog with license key input
- Download progress tracking
- Enable/disable controls
- Error handling and user feedback

## Testing

### Local Development

1. Generate sample manifest:
   ```bash
   ./Scripts/create_sample_plugin.sh
   ```

2. Start local server:
   ```bash
   python -m http.server 8000
   ```

3. Update configuration in `AccessoryPluginManager.swift`:
   ```swift
   static let `default` = PluginRepositoryConfig(
       baseURL: "http://localhost:8000",
       manifestURL: "http://localhost:8000/manifest.json",
       assetsURL: "http://localhost:8000/assets",
       apiKey: nil,
       licenseValidationURL: "http://localhost:8000/validate"
   )
   ```

### Testing Workflow

1. Build and run the app
2. Open Accessory Store from menu
3. Browse available plugins
4. Test purchase flow with sample license keys
5. Verify asset downloading and rendering
6. Test enable/disable functionality

## Production Deployment

### Server Setup

1. **Domain**: Set up a dedicated domain (e.g., `plugins.bangocat.app`)
2. **SSL**: Install valid SSL certificate
3. **CDN**: Configure CDN for asset delivery
4. **Monitoring**: Set up logging and monitoring
5. **Backup**: Implement backup and disaster recovery

### License Management

1. **Key Generation**: Use cryptographically secure random generation
2. **Validation**: Implement server-side license validation
3. **Device Tracking**: Track device IDs for license enforcement
4. **Rate Limiting**: Prevent abuse and license sharing

### Analytics

Track important metrics:

- Plugin discovery and download counts
- Purchase conversion rates
- License validation attempts
- Error rates and types
- Revenue tracking

## Future Enhancements

### Planned Features

1. **Plugin Updates**: Version management and automatic updates
2. **Subscription Model**: Monthly/yearly access to all plugins
3. **Bundle Discounts**: Discounted pricing for multiple plugins
4. **Trial Periods**: Time-limited trials for new plugins
5. **User Reviews**: Rating and review system
6. **Plugin Categories**: Better organization and filtering

### Technical Improvements

1. **Delta Updates**: Efficient updates for large assets
2. **Offline Support**: Better caching and offline functionality
3. **Advanced Positioning**: More sophisticated positioning system
4. **Animation Support**: Plugin-specific animations
5. **Customization**: User-configurable accessory properties

## Troubleshooting

### Common Issues

1. **Plugin not loading**: Check network connectivity and server status
2. **License validation fails**: Verify license key format and server configuration
3. **Assets not downloading**: Check file permissions and server setup
4. **Accessories not rendering**: Verify asset format and positioning

### Debug Information

Enable debug logging by setting:
```swift
// In AccessoryPluginManager.swift
private let debugMode = true
```

This will log detailed information about:
- Plugin discovery attempts
- License validation requests
- Asset download progress
- Rendering operations

## Support

For plugin development questions or issues:

1. Check the server configuration in `PluginRepositoryServer.swift`
2. Review the sample manifest generated by `create_sample_plugin.sh`
3. Test with the local development setup
4. Verify all API endpoints are working correctly

The plugin system is designed to be secure, scalable, and user-friendly while providing a monetization path that doesn't interfere with the core free functionality of BangoCat.