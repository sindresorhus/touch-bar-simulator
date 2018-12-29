import Cocoa
import Sparkle

private let defaults = UserDefaults.standard

final class AppDelegate: NSObject, NSApplicationDelegate {
	lazy var window = with(TouchBarWindow()) {
		$0.alphaValue = CGFloat(defaults.double(forKey: "windowTransparency"))
	}

	lazy var statusItem = with(NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)) {
		$0.menu = statusMenu
		$0.button!.image = NSImage(named: "AppIcon") // TODO: Add proper icon
		$0.button!.toolTip = NSLocalizedString("Right or option-click for menu", comment: "Status bar item tooltip")
	}
	lazy var statusMenu = with(NSMenu()) {
		$0.delegate = self
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		defaults.register(defaults: [
			"NSApplicationCrashOnExceptions": true,
			"windowTransparency": 0.75,
			"windowDocking": TouchBarWindow.Docking.floating.rawValue
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

		docking = defaults.string(forKey: "windowDocking").flatMap { TouchBarWindow.Docking(rawValue: $0) } ?? .floating
		showOnAllDesktops = defaults.bool(forKey: "showOnAllDesktops")
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
			defaults.setValue(docking.rawValue, forKey: "windowDocking")

			statusMenuDockingItems.forEach { $0.state = .off }

			let onItem: NSMenuItem
			switch docking {
			case .floating:
				onItem = statusMenuDockingItemFloating
			case .dockedToTop:
				onItem = statusMenuDockingItemDockedToTop
			case .dockedToBottom:
				onItem = statusMenuDockingItemDockedToBottom
			}
			onItem.state = .on

			window.docking = docking
		}
	}

	var showOnAllDesktops: Bool = false {
		didSet {
			defaults.setValue(showOnAllDesktops, forKey: "showOnAllDesktops")
			statusMenuItemShowOnAllDesktops.state = showOnAllDesktops ? .on : .off
			window.showOnAllDesktops = showOnAllDesktops
		}
	}

	@objc
	func setFloating() {
		docking = .floating
	}
	@objc
	func setDockedToTop() {
		docking = .dockedToTop
	}
	@objc
	func setDockedToBottom() {
		docking = .dockedToBottom
	}

	@objc
	func toggleShowOnAllDesktops() {
		showOnAllDesktops = !showOnAllDesktops
	}
}

private func leftMouseIsDown() -> Bool {
	return NSApp.currentEvent?.type == .leftMouseDown
}
private func optionKeyIsDown() -> Bool {
	return NSApp.currentEvent?.modifierFlags.contains(.option) ?? false
}

private func statusItemShouldShowMenu() -> Bool {
	return !leftMouseIsDown() || optionKeyIsDown()
}

private var statusMenuDockingItemFloating = NSMenuItem(title: NSLocalizedString("Floating", comment: "Status menu Docking item"), action: #selector(AppDelegate.setFloating), keyEquivalent: "")
private var statusMenuDockingItemDockedToTop = NSMenuItem(title: NSLocalizedString("Docked to Top", comment: "Status menu Docking item"), action: #selector(AppDelegate.setDockedToTop), keyEquivalent: "")
private var statusMenuDockingItemDockedToBottom = NSMenuItem(title: NSLocalizedString("Docked to Bottom", comment: "Status menu Docking item"), action: #selector(AppDelegate.setDockedToBottom), keyEquivalent: "")
private var statusMenuDockingItems: [NSMenuItem] = [
	statusMenuDockingItemFloating,
	statusMenuDockingItemDockedToTop,
	statusMenuDockingItemDockedToBottom
].map { $0.indentationLevel = 1; return $0 }

private var statusMenuItemShowOnAllDesktops = NSMenuItem(title: NSLocalizedString("Show on All Desktops", comment: "Status menu item"), action: #selector(AppDelegate.toggleShowOnAllDesktops), keyEquivalent: "")

private var statusMenuOptionItems: [NSMenuItem] = [

	NSMenuItem(title: NSLocalizedString("Docking", comment: "Status menu label item"), action: nil, keyEquivalent: ""),
	statusMenuDockingItemFloating,
	statusMenuDockingItemDockedToTop,
	statusMenuDockingItemDockedToBottom,

	NSMenuItem.separator(),

	statusMenuItemShowOnAllDesktops,

	NSMenuItem.separator(),

	NSMenuItem(title: NSLocalizedString("Quit Touch Bar Simulator", comment: "Status menu item"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")

]

extension AppDelegate: NSMenuDelegate {
	func menuNeedsUpdate(_ menu: NSMenu) {
		guard statusItemShouldShowMenu() else {
			menu.removeAllItems()
			return
		}
		guard menu.numberOfItems != statusMenuOptionItems.count else {
			return
		}
		menu.removeAllItems()
		if #available(macOS 10.14, *) {
			menu.items = statusMenuOptionItems
		} else {
			statusMenuOptionItems.forEach { menu.addItem($0) }
		}
	}

	func menuWillOpen(_ menu: NSMenu) {
		guard !statusItemShouldShowMenu() else {
			return
		}
		statusItemButtonClicked()
	}

	func statusItemButtonClicked() {
		toggleView()
		if window.isVisible { window.orderFront(nil) }
	}
}
