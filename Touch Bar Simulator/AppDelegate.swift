import SwiftUI
import Sparkle
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
	lazy var window = with(TouchBarWindow()) {
		$0.alphaValue = CGFloat(Defaults[.windowTransparency])
		$0.setUp()
	}

	lazy var statusItem = with(NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)) {
		$0.menu = with(NSMenu()) {
			$0.delegate = self
		}
		$0.button!.image = NSImage(named: "MenuBarIcon")
		$0.button!.toolTip = "Right-click or option-click for menu"
		$0.button!.preventsHighlight = true
	}

	func applicationWillFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(defaults: [
			"NSApplicationCrashOnExceptions": true
		])
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		checkAccessibilityPermission()
		_ = SUUpdater()
		_ = window
		_ = statusItem

		KeyboardShortcuts.onKeyUp(for: .toggleTouchBar) { [self] in
			toggleView()
		}
	}

	func checkAccessibilityPermission() {
		// We intentionally don't use the system prompt as our dialog explains it better.
		let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
		if AXIsProcessTrustedWithOptions(options) {
			return
		}

		"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility".openUrl()

		let alert = NSAlert()
		alert.messageText = "Touch Bar Simulator needs accessibility access."
		alert.informativeText = "In the System Preferences window that just opened, find “Touch Bar Simulator” in the list and check its checkbox. Then click the “Continue” button here."
		alert.addButton(withTitle: "Continue")
		alert.addButton(withTitle: "Quit")

		guard alert.runModal() == .alertFirstButtonReturn else {
			App.quit()
			return
		}

		App.relaunch()
	}

	@objc
	func captureScreenshot() {
		let KEY_6: CGKeyCode = 0x58
		pressKey(keyCode: KEY_6, flags: [.maskShift, .maskCommand])
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

		menu.addItem(NSMenuItem(title: "Docking", action: nil, keyEquivalent: ""))
		var statusMenuDockingItems: [NSMenuItem] = []
		statusMenuDockingItems.append(NSMenuItem("Floating").bindChecked(to: .windowDocking, value: .floating))
		statusMenuDockingItems.append(NSMenuItem("Docked to Top").bindChecked(to: .windowDocking, value: .dockedToTop))
		statusMenuDockingItems.append(NSMenuItem("Docked to Bottom").bindChecked(to: .windowDocking, value: .dockedToBottom))
		for item in statusMenuDockingItems {
			item.indentationLevel = 1
		}
		menu.items.append(contentsOf: statusMenuDockingItems)

		func sliderMenuItem(_ title: String, boundTo key: Defaults.Key<Double>, min: Double, max: Double) -> NSMenuItem {
			let menuItem = NSMenuItem(title)
			let containerView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 20)))

			let slider = MenubarSlider().alwaysRedisplayOnValueChanged()
			slider.frame = CGRect(x: 20, y: 4, width: 180, height: 11)
			slider.minValue = min
			slider.maxValue = max
			slider.bindDoubleValue(to: key)

			containerView.addSubview(slider)
			slider.translatesAutoresizingMaskIntoConstraints = false
			slider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24).isActive = true
			slider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -9).isActive = true
			slider.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
			menuItem.view = containerView

			return menuItem
		}

		if Defaults[.windowDocking] != .floating {
			menu.addItem(NSMenuItem("Padding"))
			menu.addItem(sliderMenuItem("Padding", boundTo: .windowPadding, min: 0.0, max: 120.0))
		}

		menu.addItem(NSMenuItem("Opacity"))
		menu.addItem(sliderMenuItem("Opacity", boundTo: .windowTransparency, min: 0.5, max: 1.0))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Capture Screenshot", keyEquivalent: "6", keyModifiers: [.shift, .command]) { [self] _ in
			captureScreenshot()
		})

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Show on All Desktops").bindState(to: .showOnAllDesktops))

		menu.addItem(NSMenuItem("Hide and Show Automatically").bindState(to: .dockBehavior))

		menu.addItem(NSMenuItem("Launch at Login", isChecked: LaunchAtLogin.isEnabled) { item in
			item.isChecked.toggle()
			LaunchAtLogin.isEnabled = item.isChecked
		})

		menu.addItem(NSMenuItem("Keyboard Shortcuts…") { [self] _ in
			guard let button = statusItem.button else {
				return
			}
			let popover = NSPopover()
			popover.contentViewController = NSHostingController(rootView: KeyboardShortcutsView())
			popover.behavior = .transient
			popover.show(relativeTo: button.frame, of: button, preferredEdge: .maxY)
		})

		menu.addItem(NSMenuItem.separator())

		menu.addItem(NSMenuItem("Quit Touch Bar Simulator", keyEquivalent: "q") { _ in
			NSApp.terminate(nil)
		})
	}

	private func statusItemShouldShowMenu() -> Bool {
		!NSApp.isLeftMouseDown || NSApp.isOptionKeyDown
	}

	func menuNeedsUpdate(_ menu: NSMenu) {
		update(menu: menu)
	}

	func menuWillOpen(_ menu: NSMenu) {
		let shouldShowMenu = statusItemShouldShowMenu()

		statusItem.button!.preventsHighlight = !shouldShowMenu
		if !shouldShowMenu {
			statusItemButtonClicked()
		}
	}

	private func statusItemButtonClicked() {
		// When the user explicitly wants the Touch Bar to appear then `dockBahavior` should be disabled.
		// This is also how the macOS Dock behaves.
		Defaults[.dockBehavior] = false

		toggleView()

		if window.isVisible {
			window.orderFront(nil)
		}
	}
}
