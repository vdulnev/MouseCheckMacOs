# Click Monitor - Settings Feature

## Overview
The Click Monitor app now includes customizable settings for adjusting the duration of click phases.

## Features Added

### 1. **Configurable Durations**
- **Allowing Phase Duration**: 1.0 - 10.0 seconds (default: 3.0s)
- **Prohibiting Phase Duration**: 1.0 - 10.0 seconds (default: 2.0s)
- Both durations can be adjusted in 0.5-second increments

### 2. **Settings UI**
- **Settings Button**: Gear icon in the top-right of the main view
- **Settings Sheet**: Modal window with sliders for each duration
- **Visual Feedback**: 
  - Green slider for allowing phase
  - Red slider for prohibiting phase
  - Real-time duration display
  - Total cycle time summary
- **Reset to Defaults**: Quick button to restore 3s/2s defaults

### 3. **Real-time Updates**
- Phase indicator automatically updates to show current durations
- Changes apply immediately to the ClickMonitor
- Settings persist during the app session

## Files Modified

### `ClickMonitor.swift`
- Changed `allowingDuration` and `prohibitingDuration` from constants to public variables
- Durations can now be modified at runtime

### `ClickMonitorView.swift`
- Added settings button (gear icon)
- Added state variables for duration settings
- Added `.onChange` handlers to sync durations with ClickMonitor
- Added `.sheet` modifier for settings presentation
- Updated PhaseIndicatorView to display dynamic durations

### `SettingsView.swift` (New)
- Comprehensive settings interface
- Dual sliders with color-coded sections
- Summary section showing total cycle time
- Reset to defaults functionality
- Proper macOS-style form layout

## Usage

1. **Open Settings**: Click the gear icon ⚙️ in the top-right corner
2. **Adjust Durations**: 
   - Drag the green slider to change allowing phase duration
   - Drag the red slider to change prohibiting phase duration
3. **View Summary**: See total cycle time at the bottom
4. **Reset**: Click "Reset to Defaults" to restore 3s/2s
5. **Apply**: Click "Done" to close settings (changes apply immediately)

## Code Example

```swift
// Settings are bound to the monitor
monitor.allowingDuration = .seconds(5.0)   // 5 second allowing phase
monitor.prohibitingDuration = .seconds(1.5) // 1.5 second prohibiting phase
```

## Future Enhancements

Potential additions:
- Persistent settings using UserDefaults or AppStorage
- Presets (Fast: 1s/1s, Standard: 3s/2s, Slow: 5s/3s)
- Custom keyboard shortcuts for common settings
- Visual countdown timer during phases
