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
		$0.button!.image = NSImage(named: "AppIcon") // TODO: Add proper icon
		$0.button!.toolTip = "Right or option-click for menu"
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(defaults: [
			"NSApplicationCrashOnExceptions": true
		])
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.servicesProvider = self
		_ = SUUpdater()
		_ = statusItem

		docking = defaults[.windowDocking]
		showOnAllDesktops = defaults[.showOnAllDesktops]
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

	var docking: TouchBarWindow.Docking = .floating {
		didSet {
			defaults[.windowDocking] = docking
			window.docking = docking
		}
	}

	var showOnAllDesktops: Bool = false {
		didSet {
			defaults[.showOnAllDesktops] = showOnAllDesktops
			window.showOnAllDesktops = showOnAllDesktops
		}
	}

}

extension AppDelegate: NSMenuDelegate {
	private func update(menu: NSMenu) {
		menu.removeAllItems()

		guard statusItemShouldShowMenu() else {
			return
		}

		menu.addItem(NSMenuItem(title: "Docking", action: nil, keyEquivalent: ""))
		var statusMenuDockingItems: [NSMenuItem] = []
		statusMenuDockingItems.append(NSMenuItem.menuItem("Floating", isOn: docking == .floating) { _ in
			self.docking = .floating
		})
		statusMenuDockingItems.append(NSMenuItem.menuItem("Docked to Top", isOn: docking == .dockedToTop) { _ in
			self.docking = .dockedToTop
		})
		statusMenuDockingItems.append(NSMenuItem.menuItem("Docked to Bottom", isOn: docking == .dockedToBottom) { _ in
			self.docking = .dockedToBottom
		})
		for item in statusMenuDockingItems {
			item.indentationLevel = 1
		}
		menu.items.append(contentsOf: statusMenuDockingItems)

		menu.addItem(NSMenuItem(title: "Transparency", action: nil, keyEquivalent: ""))
		let transparencyItem = NSMenuItem.menuItem("Transparency") { _ in }
		let transparencyView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: 180, height: 20)))
		let slider = window.makeTransparencySlider(transparencyView)
		slider.onAction = { sender in
			self.window.setTransparency(sender: sender)
		}
		transparencyView.addSubview(slider)
		slider.translatesAutoresizingMaskIntoConstraints = false
		slider.leadingAnchor.constraint(equalTo: transparencyView.leadingAnchor, constant: 40).isActive = true
		slider.trailingAnchor.constraint(equalTo: transparencyView.trailingAnchor, constant: -20).isActive = true
		slider.centerYAnchor.constraint(equalTo: transparencyView.centerYAnchor).isActive = true
		transparencyItem.view = transparencyView
		menu.addItem(transparencyItem)

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem.menuItem("Take Screenshot", keyEquivalent: "6", keyModifiers: [.shift, .command]) { _ in
			self.captureScreenshot()
		})

		menu.addItem(NSMenuItem.separator())

		let showOnAllDesktopsItem = NSMenuItem.menuItem("Show on All Desktops", isOn: defaults[.showOnAllDesktops]) { _ in
			self.showOnAllDesktops = !self.showOnAllDesktops
		}
		menu.addItem(showOnAllDesktopsItem)

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem.menuItem("Quit Touch Bar Simulator", keyEquivalent: "q") { _ in
			NSApp.terminate(nil)
		})
	}

	private func statusItemShouldShowMenu() -> Bool {
		return !NSApp.leftMouseIsDown() || NSApp.optionKeyIsDown()
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
		toggleView()
		if window.isVisible { window.orderFront(nil) }
	}
}
