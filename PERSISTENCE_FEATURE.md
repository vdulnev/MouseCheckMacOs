# Settings Persistence Feature

## Overview
The Click Monitor app now automatically saves your settings and restores them when you restart the app.

## What Gets Saved
- **Allowing Duration**: Your custom green phase duration (1-10 seconds)
- **Prohibiting Duration**: Your custom red phase duration (1-10 seconds)

## How It Works

### @AppStorage Property Wrapper
```swift
@AppStorage("allowingDuration") private var allowingDuration: Double = 3.0
@AppStorage("prohibitingDuration") private var prohibitingDuration: Double = 2.0
```

### Automatic Persistence
- Settings are saved **immediately** when you change them
- No "Save" button needed
- No manual action required
- Stored in **UserDefaults**

### On App Launch
```swift
.onAppear {
    // Restore saved settings to monitor
    monitor.allowingDuration = .seconds(allowingDuration)
    monitor.prohibitingDuration = .seconds(prohibitingDuration)
}
```

## User Experience

### First Launch
- Default values: 3.0s allowing, 2.0s prohibiting
- Standard behavior

### Adjusting Settings
1. Click settings gear ⚙️
2. Adjust sliders
3. Close settings
4. **Values saved automatically** ✅

### After Restart
1. Quit app
2. Relaunch app
3. **Your custom settings are restored** ✅
4. No need to reconfigure

## Technical Details

### Storage Location
- **macOS**: `~/Library/Preferences/com.yourcompany.MouseCheck.plist`
- **iOS**: App sandbox UserDefaults

### Storage Keys
- `"allowingDuration"` - Double (seconds)
- `"prohibitingDuration"` - Double (seconds)

### Default Values
If no saved settings exist (first launch):
- Allowing: 3.0 seconds
- Prohibiting: 2.0 seconds

### Reset to Defaults
Users can click "Reset to Defaults" button in settings to restore:
- Allowing: 3.0 seconds
- Prohibiting: 2.0 seconds

This also saves the default values to UserDefaults.

## Implementation

### Files Modified

#### `ClickMonitorView.swift`
```swift
// Changed from @State to @AppStorage
@AppStorage("allowingDuration") private var allowingDuration: Double = 3.0
@AppStorage("prohibitingDuration") private var prohibitingDuration: Double = 2.0

// Added initialization on appear
.onAppear {
    monitor.allowingDuration = .seconds(allowingDuration)
    monitor.prohibitingDuration = .seconds(prohibitingDuration)
}
```

#### `SettingsView.swift`
```swift
// Added auto-save indicator
Label("Auto-saved", systemImage: "checkmark.circle.fill")
    .font(.caption)
    .foregroundStyle(.green)

// Added help text
Text("Settings are automatically saved and will persist after restarting the app.")
```

## Benefits

✅ **Convenience**: No need to reconfigure every time
✅ **User-friendly**: Automatic saving, no extra buttons
✅ **Reliable**: Uses system UserDefaults (battle-tested)
✅ **Fast**: Instant save and restore
✅ **Simple**: No complex file management

## Testing Persistence

1. **Change Settings**:
   - Open Settings
   - Set allowing to 5.0s
   - Set prohibiting to 1.5s
   - Close Settings

2. **Verify In-App**:
   - Phase indicator shows "5.0s" and "1.5s"
   - Cycle uses new timings

3. **Restart App**:
   - Quit app (⌘Q)
   - Relaunch app
   - Open Settings

4. **Verify Persistence**:
   - ✅ Allowing still shows 5.0s
   - ✅ Prohibiting still shows 1.5s
   - ✅ Cycles use saved timings

## Future Enhancements

Potential additions:
- Save auto-cycling state
- Save window position/size
- Export/import settings
- Multiple profiles
- Settings sync via iCloud
