import Cocoa
import Defaults

final class TouchBarWindow: NSPanel {
	enum Docking: String, Codable {
		case floating
		case dockedToTop
		case dockedToBottom

		func dock(window: TouchBarWindow, padding: CGFloat) {
			switch self {
			case .floating:
				window.addTitlebar()
			case .dockedToTop:
				window.removeTitlebar()
			case .dockedToBottom:
				window.removeTitlebar()
			}

			reposition(window: window, padding: padding)
		}

		func reposition(window: NSWindow, padding: CGFloat) {
			switch self {
			case .floating:
				if let prevPosition = Defaults[.lastFloatingPosition] {
					window.setFrameOrigin(prevPosition)
				}
			case .dockedToTop:
				window.moveTo(x: .center, y: .top)
				window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: window.frame.origin.y - padding))
			case .dockedToBottom:
				window.moveTo(x: .center, y: .bottom)
				window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: window.frame.origin.y + padding))
			}
		}
	}

	override var canBecomeMain: Bool { false }

	override var canBecomeKey: Bool { false }

	var docking: Docking = .floating {
		didSet {
			if oldValue == .floating && docking != .floating {
				Defaults[.lastFloatingPosition] = frame.origin
			}

			if docking == .floating {
				dockBehavior = false
			}

			// Prevent the Touch Bar from momentarily becoming visible.
			if docking == .floating || !dockBehavior {
				stopDockBehaviorTimer()
				docking.dock(window: self, padding: CGFloat(Defaults[.windowPadding]))
				setIsVisible(true)
				orderFront(nil)
				return
			}

			// When docking is set to `dockedToTop` or `dockedToBottom` dockBehavior should start.
			if dockBehavior {
				setIsVisible(false)
				docking.dock(window: self, padding: CGFloat(Defaults[.windowPadding]))
				startDockBehaviorTimer()
			}
		}
	}

	@objc
	func didChangeScreenParameters(_ notification: Notification) {
		docking.reposition(window: self, padding: CGFloat(Defaults[.windowPadding]))
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

	var dockBehaviorTimer = Timer()
	var showTouchBarTimer = Timer()

	func startDockBehaviorTimer() {
		stopDockBehaviorTimer()

		dockBehaviorTimer = Timer.scheduledTimer(
			timeInterval: 0.1,
			target: self,
			selector: #selector(handleDockBehavior),
			userInfo: nil,
			repeats: true
		)
	}

	func stopDockBehaviorTimer() {
		dockBehaviorTimer.invalidate()
		dockBehaviorTimer = Timer()
	}

	var dockBehavior: Bool = Defaults[.dockBehavior] {
		didSet {
			Defaults[.dockBehavior] = dockBehavior
			if docking == .dockedToBottom || docking == .dockedToTop {
				Defaults[.lastWindowDockingWithDockBehavior] = docking
			}

			if dockBehavior {
				if docking == .dockedToBottom || docking == .dockedToTop {
					docking = Defaults[.lastWindowDockingWithDockBehavior]
					startDockBehaviorTimer()
				} else if docking == .floating {
					Defaults[.windowDocking] = Defaults[.lastWindowDockingWithDockBehavior]
				}
			} else {
				stopDockBehaviorTimer()
				setIsVisible(true)
			}
		}
	}

	@objc
	func handleDockBehavior() {
		guard
			let visibleFrame = NSScreen.main?.visibleFrame,
			let screenFrame = NSScreen.main?.frame
		else {
			return
		}

		var detectionRect: NSRect = .zero
		if docking == .dockedToBottom {
			if isVisible {
				detectionRect = CGRect(
					x: 0,
					y: 0,
					width: visibleFrame.width,
					height: frame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness + CGFloat(Defaults[.windowPadding]))
				)
			} else {
				detectionRect = CGRect(x: 0, y: 0, width: visibleFrame.width, height: 1)
			}
		} else if docking == .dockedToTop {
			if isVisible {
				detectionRect = CGRect(
					x: 0,
					// Without `+ 1`, the Touch Bar would glitch (toggling rapidly).
					y: screenFrame.height - frame.height - NSStatusBar.system.thickness - CGFloat(Defaults[.windowPadding]) + 1,
					width: visibleFrame.width,
					height: frame.height + NSStatusBar.system.thickness + CGFloat(Defaults[.windowPadding]))
			} else {
				detectionRect = CGRect(
					x: 0,
					y: screenFrame.height,
					width: visibleFrame.width,
					height: 1)
			}
		}

		let mouseLocation = NSEvent.mouseLocation
		if detectionRect.contains(mouseLocation) {
			dismissAnimationDidRun = false

			guard
				!showTouchBarTimer.isValid,
				!showAnimationDidRun
			else {
				return
			}

			showTouchBarTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
				self.performActionWithAnimation(action: .show)
				self.showAnimationDidRun = true
			}
		} else {
			showTouchBarTimer.invalidate()
			showTouchBarTimer = Timer()
			showAnimationDidRun = false

			if isVisible && !dismissAnimationDidRun {
				performActionWithAnimation(action: .dismiss)
				dismissAnimationDidRun = true
			}
		}
	}

	var showAnimationDidRun = false
	var dismissAnimationDidRun = false

	func performActionWithAnimation(action: TouchBarAction) {
		guard
			docking == .dockedToTop ||
			docking == .dockedToBottom
		else {
			return
		}

		var endY: CGFloat!

		if action == .show {
			self.docking.reposition(window: self, padding: -frame.height)
			setIsVisible(true)

			if docking == .dockedToTop {
				endY = frame.minY - frame.height - CGFloat(Defaults[.windowPadding])
			} else if docking == .dockedToBottom {
				endY = frame.minY + frame.height + CGFloat(Defaults[.windowPadding])
			}
		} else if action == .dismiss {
			if docking == .dockedToTop {
				endY = frame.minY + frame.height + NSStatusBar.system.thickness + CGFloat(Defaults[.windowPadding])
			} else if docking == .dockedToBottom {
				endY = 0 - frame.height
			}
		}

		var endFrame = frame
		endFrame.origin.y = endY

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			animator().setFrame(endFrame, display: false, animate: true)
		}, completionHandler: {
			if action == .show {
				self.docking.reposition(window: self, padding: CGFloat(Defaults[.windowPadding]))
			} else if action == .dismiss {
				self.setIsVisible(false)
				self.docking.reposition(window: self, padding: 0)
			}
		})
	}

	enum TouchBarAction {
		case show
		case dismiss
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

	private var defaultsObservations: [DefaultsObservation] = []

	func setUp() {
		let view = contentView!
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.black.cgColor

		let touchBarView = TouchBarView()
		setContentSize(touchBarView.bounds.adding(padding: 5).size)
		touchBarView.frame = touchBarView.frame.centered(in: view.bounds)
		view.addSubview(touchBarView)

		for observation in [
			// swiftlint:disable:next unowned_variable_capture
			Defaults.observe(.windowTransparency) { [unowned self] change in
			    self.alphaValue = CGFloat(change.newValue)
			},
			// swiftlint:disable:next unowned_variable_capture
			Defaults.observe(.windowDocking) { [unowned self] change in
				self.docking = change.newValue
			},
			// swiftlint:disable:next unowned_variable_capture
			Defaults.observe(.windowPadding) { [unowned self] change in
				self.docking.reposition(window: self, padding: CGFloat(change.newValue))
			},
			// TODO: We could maybe simplify this by creating another `Default` extension to bind a default to a KeyPath:
			// `defaults.bind(.showOnAllDesktops, to: \.showOnAllDesktops)`
			// swiftlint:disable:next unowned_variable_capture
			Defaults.observe(.showOnAllDesktops) { [unowned self] change in
				self.showOnAllDesktops = change.newValue
			},
			// swiftlint:disable:next unowned_variable_capture
			Defaults.observe(.dockBehavior) { [unowned self] change in
				self.dockBehavior = change.newValue
			}
		] {
			observation.tieToLifetime(of: self)
		}

		center()
		setFrameOrigin(CGPoint(x: frame.origin.x, y: 100))

		setFrameUsingName(Constants.windowAutosaveName)
		setFrameAutosaveName(Constants.windowAutosaveName)

		// Prevent the Touch Bar from momentarily becoming visible.
		if !dockBehavior {
			orderFront(nil)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(didChangeScreenParameters(_:)), name: NSApplication.didChangeScreenParametersNotification, object: nil)
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
