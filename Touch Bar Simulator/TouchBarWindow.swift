import Cocoa
import Defaults

final class TouchBarWindow: NSPanel {
	enum Docking: String, Codable {
		case floating, dockedToTop, dockedToBottom

		func dock(window: TouchBarWindow) {
			switch self {
			case .floating:
				window.addTitlebar()
				if let prevPosition = defaults[.lastFloatingPosition] {
					window.setFrameOrigin(prevPosition)
				}
			case .dockedToTop:
				window.removeTitlebar()
				window.moveTo(x: .center, y: .top)
			case .dockedToBottom:
				window.removeTitlebar()
				window.moveTo(x: .center, y: .bottom)
			}
		}
	}

	var docking: Docking? {
		didSet {
			if oldValue == .floating && docking != .floating {
				defaults[.lastFloatingPosition] = frame.origin
			}

			// Prevent the touch bar from shortly becoming visible.
			if self.docking != nil {
				if self.docking! == .floating {
					stopDockBehaviorTimer()
					docking?.dock(window: self)
					setIsVisible(true)
					orderFront(nil)
					return
				}
			}

			if !dockBehavior {
				stopDockBehaviorTimer()
				docking?.dock(window: self)
				setIsVisible(true)
				orderFront(nil)
				return
			}

			// When docking is set to `dockedToTop` or `dockedToBottom` dockBehavior should start
			if dockBehavior {
				setIsVisible(false)
				docking?.dock(window: self)
				startDockBehaviorTimer()
			}
		}
	}

	var showOnAllDesktops: Bool = false {
		didSet {
			if showOnAllDesktops {
				collectionBehavior = .canJoinAllSpaces
			} else {
				collectionBehavior = .moveToActiveSpace
			}
		}
	}

	var dockBehaviorTimer: Timer?

	func startDockBehaviorTimer() {
		stopDockBehaviorTimer()
		dockBehaviorTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleDockBehavior), userInfo: nil, repeats: true)
		dockBehaviorTimer!.fire()
	}

	func stopDockBehaviorTimer() {
		guard dockBehaviorTimer != nil else {
			return
		}
		dockBehaviorTimer!.invalidate()
		dockBehaviorTimer = nil
	}

	var dockBehavior: Bool = defaults[.dockBehavior] {
		didSet {
			if dockBehavior {
				guard self.docking != nil &&
					self.docking! == .dockedToBottom ||
					self.docking! == .dockedToTop else {
					return
				}
				startDockBehaviorTimer()
			} else {
				stopDockBehaviorTimer()
			}
		}
	}

	@objc
	func handleDockBehavior() {
		guard self.docking != nil else {
			return
		}
		guard let screen = NSScreen.main else {
			return
		}
		var detectionRect: NSRect = .zero
		if self.docking! == .dockedToBottom {
			if self.isVisible {
				detectionRect = NSRect(x: 0, y: 0, width: screen.frame.width, height: self.frame.height)
			} else {
				detectionRect = NSRect(x: 0, y: 0, width: screen.frame.width, height: 1)
			}
		} else if self.docking! == .dockedToTop {
			if self.isVisible {
				detectionRect = NSRect(
					x: 0,
					// without `+ 1` the touch bar would glitch (toggling rapidly).
					y: screen.frame.height - self.frame.height - NSStatusBar.system.thickness + 1,
					width: screen.frame.width,
					height: self.frame.height + NSStatusBar.system.thickness)
			} else {
				detectionRect = NSRect(
					x: 0,
					y: screen.frame.height,
					width: screen.frame.width,
					height: 1)
			}
		}
		let mouseLocation = NSEvent.mouseLocation
		if detectionRect.contains(mouseLocation) {
			if !self.isVisible {
				self.setIsVisible(true)
			}
		} else {
			if self.isVisible {
				self.setIsVisible(false)
			}
		}
	}

	func addTitlebar() {
		styleMask.insert(.titled)
		title = "Touch Bar Simulator"

		guard let toolbarView = self.toolbarView else {
			return
		}

		toolbarView.addSubviews(
			makeScreenshotButton(toolbarView),
			makeTransparencySlider(toolbarView)
		)
	}

	func removeTitlebar() {
		styleMask.remove(.titled)
	}

	func makeScreenshotButton(_ toolbarView: NSView) -> NSButton {
		let button = NSButton()
		button.image = NSImage(named: "ScreenshotButton")
		button.imageScaling = .scaleProportionallyDown
		button.isBordered = false
		button.bezelStyle = .shadowlessSquare
		button.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
		button.action = #selector(AppDelegate.captureScreenshot)
		return button
	}

	private var transparencySlider: ToolbarSlider?

	func makeTransparencySlider(_ parentView: NSView) -> ToolbarSlider {
		let slider = ToolbarSlider().alwaysRedisplayOnValueChanged().bindDoubleValue(to: .windowTransparency)
		slider.frame = CGRect(x: parentView.frame.width - 160, y: 4, width: 140, height: 11)
		slider.minValue = 0.5
		return slider
	}

	override var canBecomeMain: Bool {
		return false
	}

	override var canBecomeKey: Bool {
		return false
	}

	private var defaultsObservations: [DefaultsObservation] = []

	func setUp() {
		let view = contentView!
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.black.cgColor

		let touchBarView = TouchBarView()
		setContentSize(touchBarView.bounds.adding(padding: 5).size)
		touchBarView.frame = touchBarView.frame.centered(in: view.bounds)
		view.addSubview(touchBarView)

		// TODO: These could use the `observe` method with `tiedToLifetimeOf` so we don't have to manually invalidate them.
		defaultsObservations.append(defaults.observe(.windowTransparency) { change in
			self.alphaValue = CGFloat(change.newValue)
		})

		defaultsObservations.append(defaults.observe(.windowDocking) { change in
			self.docking = change.newValue
		})

		// TODO: We could maybe simplify this by creating another `Default` extension to bind a default to a KeyPath:
		// `defaults.bind(.showOnAllDesktops, to: \.showOnAllDesktop)`
		defaultsObservations.append(defaults.observe(.showOnAllDesktops) { change in
			self.showOnAllDesktops = change.newValue
		})

		defaultsObservations.append(defaults.observe(.dockBehavior) { change in
			self.dockBehavior = change.newValue
		})

		center()
		setFrameOrigin(CGPoint(x: frame.origin.x, y: 100))

		setFrameUsingName(Constants.windowAutosaveName)
		setFrameAutosaveName(Constants.windowAutosaveName)

		// Prevent the touch bar from shortly becoming visible.
		if !dockBehavior {
			orderFront(nil)
		}
	}

	deinit {
		for observation in defaultsObservations {
			observation.invalidate()
		}
	}

	convenience init() {
		self.init(
			contentRect: .zero,
			styleMask: [
				.titled,
				.closable,
				.nonactivatingPanel,
				.hudWindow,
				.utilityWindow
			],
			backing: .buffered,
			defer: false
		)
		self.level = .assistiveTechHigh

		self._setPreventsActivation(true)
		self.isRestorable = true
		self.hidesOnDeactivate = false
		self.worksWhenModal = true
		self.acceptsMouseMovedEvents = true
		self.isMovableByWindowBackground = false
	}
}
