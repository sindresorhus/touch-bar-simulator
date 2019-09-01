import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSWorkspace.shared.launchApplication(withBundleIdentifier: "com.sindresorhus.Touch-Bar-Simulator", options: [], additionalEventParamDescriptor: nil, launchIdentifier: nil)
		NSApp.terminate(self)
    }
}
