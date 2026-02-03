import SwiftUI

@main
struct ClickMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ClickMonitorView()
        }
        .commands {
            // Remove "New Window" command since we want single window
            CommandGroup(replacing: .newItem) { }
        }
    }
}
// AppDelegate to handle window closing behavior
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

