import Cocoa
import Sparkle

private let defaults = UserDefaults.standard

final class AppDelegate: NSObject, NSApplicationDelegate {
	lazy var window = with(TouchBarWindow()) {
		$0.delegate = self
		$0.alphaValue = CGFloat(defaults.double(forKey: "windowTransparency"))
	}

	lazy var toolbarView: NSView = self.window.toolbarView!

	func applicationWillFinishLaunching(_ notification: Notification) {
		defaults.register(defaults: [
			"NSApplicationCrashOnExceptions": true,
			"windowTransparency": 0.75
		])
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.servicesProvider = self

		_ = SUUpdater()

		let view = window.contentView!
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.black.cgColor

		let touchBarView = TouchBarView()
		window.setContentSize(touchBarView.bounds.adding(padding: 5).size)
		touchBarView.frame = touchBarView.frame.centered(in: view.bounds)
		view.addSubview(touchBarView)

		toolbarView.addSubviews(
			makeScreenshotButton(),
			makeTransparencySlider()
		)

		if window.frameAutosaveName.isEmpty {
			window.center()
			var origin = window.frame.origin
			origin.y = 100
			window.setFrameOrigin(origin)
		}

		window.setFrameAutosaveName("TouchBarWindowfoo4")
		window.orderFront(nil)
	}

	func makeScreenshotButton() -> NSButton {
		let button = NSButton()
		button.image = #imageLiteral(resourceName: "ScreenshotButton")
		button.imageScaling = .scaleProportionallyDown
		button.isBordered = false
		button.bezelStyle = .shadowlessSquare
		button.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
		button.action = #selector(captureScreenshot)
		return button
	}

	func makeTransparencySlider() -> ToolbarSlider {
		let slider = ToolbarSlider()
		slider.frame = CGRect(x: toolbarView.frame.width - 150, y: 4, width: 120, height: 11)
		slider.action = #selector(setTransparency)
		slider.minValue = 0.5
		slider.doubleValue = defaults.double(forKey: "windowTransparency")
		return slider
	}

	@objc
	func captureScreenshot() {
		let KEY_6: CGKeyCode = 0x58
		pressKey(keyCode: KEY_6, flags: [.maskShift, .maskCommand])
	}

	@objc
	func setTransparency(sender: ToolbarSlider) {
		window.alphaValue = CGFloat(sender.doubleValue)
		defaults.set(sender.doubleValue, forKey: "windowTransparency")
	}

	@objc
	func toggleView(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
		window.setIsVisible(!window.isVisible)
	}
}

extension AppDelegate: NSWindowDelegate {
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}
