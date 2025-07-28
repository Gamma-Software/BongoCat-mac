# BangoCat Troubleshooting Guide

## Accessibility Permissions

### Issue: Cat not animating when typing
If the cat is not animating when typing on your keyboard, the accessibility permission is not enabled.

**Solution:**
1. Go to **System Preferences** → **Security & Privacy** → **Accessibility**
2. Remove BangoCat from the list if it's there
3. Re-run the app and grant permissions when prompted

### Issue: Accessibility permission keeps being asked after reinstall
This happens because macOS treats apps with different signatures as different applications.

**Solutions:**
1. **Use the packaged app**: Download the official DMG from releases instead of building from source
2. **Remove old permissions**: Clear BangoCat from Accessibility list before reinstalling
3. **Consistent builds**: The app is now code signed to maintain consistent identity

## Common Issues

### App won't start
- Check that you're running macOS 13.0 (Ventura) or later
- Try right-clicking the app and selecting "Open" if you get a security warning

### Cat position resets
- Use the "Save Current Position" option in the context menu
- Enable "Per-App Positioning" to remember positions for different apps

### Performance issues
- Try reducing the scale in the context menu
- Disable "Scale Pulse on Input" if animations are too frequent