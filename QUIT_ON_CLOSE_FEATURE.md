# Quit on Window Close Feature

## Overview
The app now automatically quits when the user closes the main window, providing a more natural single-window app experience on macOS.

## Implementation

### AppDelegate Integration
```swift
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
```

The `@NSApplicationDelegateAdaptor` property wrapper connects a traditional AppDelegate to a SwiftUI app, allowing us to implement classic NSApplicationDelegate methods.

### Window Close Behavior
```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
```

This delegate method tells macOS to quit the entire application when the last (and only) window is closed.

### Remove "New Window" Command
```swift
.commands {
    CommandGroup(replacing: .newItem) { }
}
```

Since this is a single-window app, we remove the File → New Window menu command to prevent users from trying to create additional windows.

## User Experience

### Before
- User closes window (⌘W or red close button)
- Window closes but app remains running in Dock
- User must explicitly quit (⌘Q) or right-click Dock → Quit
- Confusing for single-window utility apps

### After
- User closes window (⌘W or red close button)
- **App automatically quits completely**
- Clean, expected behavior for utility apps
- Matches user expectations

## Behavior Comparison

| Action | macOS Default | This App |
|--------|--------------|----------|
| Close last window | App stays running | **App quits** ✅ |
| ⌘W (Close Window) | Window closes | **App quits** ✅ |
| ⌘Q (Quit) | App quits | App quits ✅ |
| Red close button | Window closes | **App quits** ✅ |

## Benefits

✅ **Natural behavior**: Matches user expectations for utility apps
✅ **No orphaned process**: App doesn't stay running invisibly
✅ **Simpler UX**: One action (close window) = quit app
✅ **Clean shutdown**: Settings saved, cycles stopped properly
✅ **Standard pattern**: Common for single-window macOS apps

## Examples of Apps Using This Pattern

Many single-window utility apps use this pattern:
- Calculator
- Activity Monitor
- Screenshot utilities
- Simple productivity tools
- Testing/development utilities

## Technical Details

### NSApplicationDelegate Method
`applicationShouldTerminateAfterLastWindowClosed(_:)` is called when:
- The last window is closed
- User hasn't explicitly quit with ⌘Q
- Returning `true` → App quits automatically
- Returning `false` → App stays running (default macOS behavior)

### SwiftUI Integration
The `@NSApplicationDelegateAdaptor` bridges traditional AppKit delegate patterns into SwiftUI's declarative app lifecycle.

### Graceful Shutdown
When the window closes:
1. User closes window
2. AppDelegate method returns `true`
3. App begins termination sequence
4. SwiftUI views are torn down
5. `@AppStorage` values are saved
6. Running tasks are cancelled
7. App process exits

## Alternative Approaches

### Window-Level Approach (Not Recommended)
```swift
// Could use .onDisappear but less clean
.onDisappear {
    NSApplication.shared.terminate(nil)
}
```

### Multiple Window Support
If you later need multiple windows, remove the AppDelegate method:
```swift
// Just remove or return false
func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Keep app running with no windows
}
```

## Testing

1. **Launch app**
2. **Close window** (⌘W or red button)
3. **Verify**: App quits completely
4. **Check Dock**: App icon disappears
5. **Relaunch**: Settings persist ✅

## Files Modified
- `ClickMonitorApp.swift`: Added AppDelegate and window commands
