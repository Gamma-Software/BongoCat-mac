# BongoCat App Store Submission Guide

This guide will help you submit BongoCat to the Mac App Store.

## Prerequisites

### 1. Apple Developer Program Membership
- **Required**: Active Apple Developer Program membership ($99/year)
- **Access**: App Store Connect, Certificates, Identifiers & Profiles

### 2. App Store Connect Setup
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Create a new app with bundle ID: `com.leaptech.bongocat`
3. Configure app metadata (description, screenshots, etc.)

### 3. Certificates and Profiles
You'll need these from Apple Developer portal:
- **Distribution Certificate**: For code signing
- **App Store Provisioning Profile**: For sandboxing
- **Team ID**: Your Apple Developer Team ID

## Step-by-Step Process

### Step 1: Prepare Your Environment

Create a `.env` file in the project root with your Apple Developer credentials:

```bash
# Apple Developer credentials
TEAM_ID="YOUR_TEAM_ID"
DISTRIBUTION_CERTIFICATE="Apple Distribution"
APP_STORE_PROVISIONING_PROFILE="BongoCat App Store"
APPLE_ID="your-apple-id@example.com"
APPLE_ID_PASSWORD="your-app-specific-password"
```

### Step 2: Build for App Store

Run the App Store build script:

```bash
./Scripts/appstore_build.sh
```

This will:
- Build the app with sandboxing enabled
- Code sign with your distribution certificate
- Create both `.app` and `.pkg` files for upload

### Step 3: Upload to App Store Connect

#### Option A: Using Xcode
1. Open Xcode
2. Go to Window → Organizer
3. Click "Distribute App"
4. Select "App Store Connect"
5. Upload your `.app` file

#### Option B: Using Application Loader
1. Download Application Loader from App Store Connect
2. Use it to upload your `.pkg` file

### Step 4: Configure App Metadata

In App Store Connect, configure:

#### App Information
- **Name**: BongoCat
- **Subtitle**: Animated Cat Overlay
- **Category**: Utilities
- **Keywords**: cat, overlay, streamer, keyboard, mouse, animation
- **Description**: See below for suggested description

#### App Description
```
BongoCat is a delightful animated cat overlay that responds to your keyboard and mouse input. Perfect for streamers, content creators, and anyone who wants a cute companion while working.

🐱 Features:
• Animated cat that reacts to keyboard and mouse input
• Per-app positioning - remembers cat location for each application
• Customizable scaling, rotation, and flip options
• Click-through mode for uninterrupted workflow
• Auto-start at login option
• Milestone notifications for input tracking

🎯 Perfect for:
• Streamers and content creators
• Developers and designers
• Anyone who wants a fun desktop companion

🔧 System Requirements:
• macOS 13.0 (Ventura) or later
• Accessibility permissions (required for input monitoring)

📱 How to Use:
1. Launch BongoCat from Applications
2. Grant accessibility permissions when prompted
3. The cat will appear and respond to your input
4. Right-click the cat for customization options
5. Use the menu bar icon for quick settings

The cat will automatically remember its position for each application, making it a seamless part of your workflow.
```

#### Screenshots
You'll need screenshots showing:
1. Cat overlay in action
2. Settings/preferences window
3. Menu bar integration
4. Different cat animations

### Step 5: Handle Accessibility Permissions

**Important**: App Store apps cannot automatically request accessibility permissions. You must:

1. **Add clear instructions** in your app description
2. **Create a setup guide** that users see on first launch
3. **Provide step-by-step instructions** for enabling accessibility

### Step 6: Submit for Review

1. Complete all metadata in App Store Connect
2. Upload screenshots and app preview videos
3. Set pricing (Free or Paid)
4. Submit for review

## Potential Issues and Solutions

### Issue 1: Accessibility Permissions
**Problem**: App Store apps can't request accessibility permissions automatically
**Solution**:
- Provide clear instructions in app description
- Create an in-app guide for first-time users
- Include a link to System Preferences

### Issue 2: Sandboxing Conflicts
**Problem**: Global input monitoring may conflict with sandboxing
**Solution**:
- The entitlements file includes necessary exceptions
- Test thoroughly with sandboxing enabled

### Issue 3: App Review Rejection
**Common reasons**:
- **Functionality**: App doesn't work as described
- **Permissions**: Unclear permission requirements
- **UI/UX**: Poor user experience

**Prevention**:
- Test thoroughly before submission
- Provide clear, accurate descriptions
- Include comprehensive setup instructions

## Testing Before Submission

### 1. Test Sandboxed Build
```bash
# Build and test the sandboxed version
./Scripts/appstore_build.sh
open "Build/appstore/package/BongoCat.app"
```

### 2. Test Accessibility Permissions
1. Install the sandboxed app
2. Launch and test accessibility permission flow
3. Verify all features work with permissions granted

### 3. Test on Clean System
1. Create a test user account
2. Install fresh copy of macOS
3. Test the complete user experience

## Post-Submission

### 1. Monitor Review Status
- Check App Store Connect for review updates
- Respond promptly to any reviewer questions

### 2. Prepare for Launch
- Plan marketing activities
- Prepare social media announcements
- Consider press outreach

### 3. Monitor User Feedback
- Respond to App Store reviews
- Address user issues quickly
- Plan updates based on feedback

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Mac App Store Submission](https://developer.apple.com/app-store/submissions/)

## Support

If you encounter issues during submission:
1. Check Apple Developer Forums
2. Contact Apple Developer Support
3. Review App Store Review Guidelines

---

**Note**: This guide assumes you have an active Apple Developer Program membership. The App Store submission process can take 1-7 days for review.