import Cocoa
import Sparkle
import Defaults

final class AppDelegate: NSObject, NSApplicationDelegate {
	lazy var window = with(TouchBarWindow()) {
		$0.alphaValue = CGFloat(defaults[.windowTransparency])
	}

	lazy var statusItem = with(NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)) {
		$0.menu = statusMenu
		$0.button!.image = NSImage(named: "AppIcon") // TODO: Add proper icon
		$0.button!.toolTip = "Right or option-click for menu"
	}
	lazy var statusMenu = with(NSMenu()) {
		createMenuItems() // Items added/removed conditionally in menuNeedsUpdate(_:)
		$0.delegate = self
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(defaults: [
			"NSApplicationCrashOnExceptions": true
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

		window.center()
		var origin = window.frame.origin
		origin.y = 100
		window.setFrameOrigin(origin)

		window.setFrameUsingName(Constants.windowAutosaveName)
		window.setFrameAutosaveName(Constants.windowAutosaveName)

		window.orderFront(nil)

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

	private var statusMenuItemFloating: NSMenuItem!
	private var statusMenuItemDockedToTop: NSMenuItem!
	private var statusMenuItemDockedToBottom: NSMenuItem!
	private var statusMenuDockingItems: [NSMenuItem]!
	private var statusMenuItemShowOnAllDesktops: NSMenuItem!
	private var statusMenuItems: [NSMenuItem]!

	var docking: TouchBarWindow.Docking = .floating {
		didSet {
			defaults[.windowDocking] = docking

			statusMenuDockingItems.forEach { $0.state = .off }

			let onItem: NSMenuItem
			switch docking {
			case .floating:
				onItem = statusMenuItemFloating
			case .dockedToTop:
				onItem = statusMenuItemDockedToTop
			case .dockedToBottom:
				onItem = statusMenuItemDockedToBottom
			}
			onItem.state = .on

			window.docking = docking
		}
	}

	var showOnAllDesktops: Bool = false {
		didSet {
			defaults[.showOnAllDesktops] = showOnAllDesktops
			statusMenuItemShowOnAllDesktops.state = showOnAllDesktops ? .on : .off
			window.showOnAllDesktops = showOnAllDesktops
		}
	}

}

extension AppDelegate: NSMenuDelegate {
	func createMenuItems() {
		func menuItem(_ title: String, keyEquivalent: String = "", action: @escaping TargetActionSender.ActionClosure) -> NSMenuItem {
			let item = NSMenuItem(title: title, action: nil, keyEquivalent: keyEquivalent)
			item.onAction = action
			return item
		}

		statusMenuItemFloating = menuItem("Floating") { _ in
			self.docking = .floating
		}
		statusMenuItemDockedToTop = menuItem("Docked to Top") { _ in
			self.docking = .dockedToTop
		}
		statusMenuItemDockedToBottom = menuItem("Docked to Bottom") { _ in
			self.docking = .dockedToBottom
		}
		statusMenuDockingItems = [
			statusMenuItemFloating,
			statusMenuItemDockedToTop,
			statusMenuItemDockedToBottom
		]
		for item in statusMenuDockingItems {
			item.indentationLevel = 1
		}

		let takeScreenshotItem = menuItem("Take Screenshot") { _ in
			self.captureScreenshot()
		}
		let transparencyItem = menuItem("Transparency") { _ in }
		let transparencyView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: 180, height: 20)))
		let slider = window.makeTransparencySlider(transparencyView)
		slider.onAction = { sender in
			self.window.setTransparency(sender: sender as! ToolbarSlider)
		}
		transparencyView.addSubview(slider)
		slider.translatesAutoresizingMaskIntoConstraints = false
		slider.leadingAnchor.constraint(equalTo: transparencyView.leadingAnchor, constant: 40).isActive = true
		slider.trailingAnchor.constraint(equalTo: transparencyView.trailingAnchor, constant: -20).isActive = true
		slider.centerYAnchor.constraint(equalTo: transparencyView.centerYAnchor).isActive = true
		transparencyItem.view = transparencyView

		statusMenuItemShowOnAllDesktops = menuItem("Show on All Desktops") { _ in
			self.showOnAllDesktops = !self.showOnAllDesktops
		}

		let quitItem = menuItem("Quit Touch Bar Simulator", keyEquivalent: "q") { _ in
			NSApp.terminate(nil)
		}

		statusMenuItems = [
			NSMenuItem(title: "Docking", action: nil, keyEquivalent: ""),
			statusMenuItemFloating,
			statusMenuItemDockedToTop,
			statusMenuItemDockedToBottom,

			NSMenuItem.separator(),

			statusMenuItemShowOnAllDesktops,

			NSMenuItem.separator(),

			takeScreenshotItem,
			NSMenuItem(title: "Transparency", action: nil, keyEquivalent: ""),
			transparencyItem,

			NSMenuItem.separator(),

			quitItem
		]
	}

	private func statusItemShouldShowMenu() -> Bool {
		return !NSApp.leftMouseIsDown() || NSApp.optionKeyIsDown()
	}

	func menuNeedsUpdate(_ menu: NSMenu) {
		guard statusItemShouldShowMenu() else {
			menu.removeAllItems()
			return
		}
		guard menu.numberOfItems != statusMenuItems.count else {
			return
		}
		menu.items = statusMenuItems
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
