import Cocoa
import Sparkle
import Defaults

final class AppDelegate: NSObject, NSApplicationDelegate {
	lazy var window = with(TouchBarWindow()) {
		$0.alphaValue = CGFloat(defaults[.windowTransparency])
		$0.setUp()
	}

	lazy var statusItem = with(NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)) {
		$0.menu = with(NSMenu()) { $0.delegate = self }
		$0.button!.image = NSImage(named: "MenuBarIcon")
		$0.button!.toolTip = NSLocalizedString("Right-click or option-click for menu", comment: "Right-click or option-click for menu")
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(defaults: [
			"NSApplicationCrashOnExceptions": true
		])
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.servicesProvider = self
		_ = SUUpdater()
		_ = window
		_ = statusItem
	}

	@objc
	func captureScreenshot() {
		let KEY_6: CGKeyCode = 0x58
		pressKey(keyCode: KEY_6, flags: [.maskShift, .maskCommand])
	}

	@objc
	func toggleView(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
		toggleView()
	}

	func toggleView() {
		window.setIsVisible(!window.isVisible)
	}
}

extension AppDelegate: NSMenuDelegate {
	private func update(menu: NSMenu) {
		menu.removeAllItems()

		guard statusItemShouldShowMenu() else {
			return
		}

		menu.addItem(NSMenuItem(title: NSLocalizedString("Docking", comment: "Docking"), action: nil, keyEquivalent: ""))
		var statusMenuDockingItems: [NSMenuItem] = []
		statusMenuDockingItems.append(NSMenuItem(NSLocalizedString("Floating", comment: "Floating")).bindChecked(to: .windowDocking, value: .floating))
		statusMenuDockingItems.append(NSMenuItem(NSLocalizedString("Docked to Top", comment: "Docked to Top")).bindChecked(to: .windowDocking, value: .dockedToTop))
		statusMenuDockingItems.append(NSMenuItem(NSLocalizedString("Docked to Bottom", comment: "Docked to Bottom")).bindChecked(to: .windowDocking, value: .dockedToBottom))
		for item in statusMenuDockingItems {
			item.indentationLevel = 1
		}
		menu.items.append(contentsOf: statusMenuDockingItems)

		menu.addItem(NSMenuItem(title: NSLocalizedString("Transparency", comment: "Transparency"), action: nil, keyEquivalent: ""))
		let transparencyItem = NSMenuItem(NSLocalizedString("Transparency", comment: "Transparency"))
		let transparencyView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 20)))
		let slider = MenubarSlider().alwaysRedisplayOnValueChanged().bindDoubleValue(to: .windowTransparency)
		slider.frame = CGRect(x: 20, y: 4, width: 180, height: 11)
		slider.minValue = 0.5
		transparencyView.addSubview(slider)
		slider.translatesAutoresizingMaskIntoConstraints = false
		slider.leadingAnchor.constraint(equalTo: transparencyView.leadingAnchor, constant: 24).isActive = true
		slider.trailingAnchor.constraint(equalTo: transparencyView.trailingAnchor, constant: -9).isActive = true
		slider.centerYAnchor.constraint(equalTo: transparencyView.centerYAnchor).isActive = true
		transparencyItem.view = transparencyView
		menu.addItem(transparencyItem)

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem(NSLocalizedString("Capture TouchBarshot", comment: "Capture TouchBarshot"), keyEquivalent: "6", keyModifiers: [.shift, .command]) { _ in
			self.captureScreenshot()
		})

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem(NSLocalizedString("Show on All Desktops", comment: "Show on All Desktops")).bindState(to: .showOnAllDesktops))

		menu.addItem(NSMenuItem(NSLocalizedString("Hide and Show Automatically", comment: "Hide and Show Automatically")).bindState(to: .dockBehavior))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem(NSLocalizedString("Quit Touch Bar Simulator", comment: "Quit Touch Bar Simulator"), keyEquivalent: "q") { _ in
			NSApp.terminate(nil)
		})
	}

	private func statusItemShouldShowMenu() -> Bool {
		return !NSApp.isLeftMouseDown || NSApp.isOptionKeyDown
	}

	func menuNeedsUpdate(_ menu: NSMenu) {
		update(menu: menu)
	}

	func menuWillOpen(_ menu: NSMenu) {
		if !statusItemShouldShowMenu() {
			statusItemButtonClicked()
		}
	}

	private func statusItemButtonClicked() {
		// When the user explicitly wants the Touch Bar to appear then `dockBahavior` should be disabled.
		// This is also how the macOS Dock behaves.
		defaults[.dockBehavior] = false

		toggleView()

		if window.isVisible {
			window.orderFront(nil)
		}
	}
}
