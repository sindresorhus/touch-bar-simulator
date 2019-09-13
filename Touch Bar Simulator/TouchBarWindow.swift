import Cocoa
import Defaults

final class TouchBarWindow: NSPanel {
	enum Docking: String, Codable {
		case floating, dockedToTop, dockedToBottom

		func dock(window: TouchBarWindow) {
			switch self {
			case .floating:
				window.addTitlebar()
			case .dockedToTop:
				window.removeTitlebar()
			case .dockedToBottom:
				window.removeTitlebar()
			}

			reposition(window: window)
		}

		func reposition(window: NSWindow) {
			switch self {
			case .floating:
				if let prevPosition = Defaults[.lastFloatingPosition] {
					window.setFrameOrigin(prevPosition)
				}
			case .dockedToTop:
				window.moveTo(x: .center, y: .top)
			case .dockedToBottom:
				window.moveTo(x: .center, y: .bottom)
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
				docking.dock(window: self)
				setIsVisible(true)
				orderFront(nil)
				return
			}

			// When docking is set to `dockedToTop` or `dockedToBottom` dockBehavior should start.
			if dockBehavior {
				setIsVisible(false)
				docking.dock(window: self)
				startDockBehaviorTimer()
			}
		}
	}

	@objc
	func didChangeScreenParameters(_ notification: Notification) {
		docking.reposition(window: self)
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
					height: frame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness)
				)
			} else {
				detectionRect = CGRect(x: 0, y: 0, width: visibleFrame.width, height: 1)
			}
		} else if docking == .dockedToTop {
			if isVisible {
				detectionRect = CGRect(
					x: 0,
					// Without `+ 1`, the Touch Bar would glitch (toggling rapidly).
					y: screenFrame.height - frame.height - NSStatusBar.system.thickness + 1,
					width: visibleFrame.width,
					height: frame.height + NSStatusBar.system.thickness)
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

	func moveToStartPoint() {
		if docking == .dockedToTop {
			moveTo(x: .center, y: .top)
		} else if docking == .dockedToBottom {
			moveTo(x: .center, y: .bottom)
		}
	}

	var showAnimationDidRun = false
	var dismissAnimationDidRun = false

	func showTouchBarWithAnimation() {
		guard
			docking == .dockedToTop ||
			docking == .dockedToBottom
		else {
			return
		}

		var startOrigin: CGPoint!
		let endFrame = frame
		setIsVisible(true)
		if docking == .dockedToTop {
			startOrigin = CGPoint(x: frame.origin.x, y: frame.origin.y + frame.height)
		} else if docking == .dockedToBottom {
			startOrigin = CGPoint(x: frame.origin.x, y: 0 - frame.height)
		}
		setFrameOrigin(startOrigin)

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			animator().setFrame(endFrame, display: false, animate: true)
		}, completionHandler: {
			self.moveToStartPoint()
		})
	}

	func dismissTouchBarWithAnimation() {
		guard
			docking == .dockedToTop ||
			docking == .dockedToBottom
		else {
			return
		}

		var endFrame = frame
		if docking == .dockedToTop {
			endFrame.origin = NSPoint(x: frame.origin.x, y: frame.origin.y + frame.height + NSStatusBar.system.thickness)
		} else if docking == .dockedToBottom {
			endFrame.origin = NSPoint(x: frame.origin.x, y: 0 - frame.height)
		}

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			animator().setFrame(endFrame, display: false, animate: true)
		}, completionHandler: {
			self.setIsVisible(false)
			self.moveToStartPoint()
		})
	}

	func performActionWithAnimation(action: TouchBarAction) {
		guard
			docking == .dockedToTop ||
			docking == .dockedToBottom
		else {
			return
		}

		var startOrigin: CGPoint!
		var endFrame = frame

		if action == .show {
			setIsVisible(true)

			if docking == .dockedToTop {
				startOrigin = CGPoint(x: frame.origin.x, y: frame.origin.y + frame.height)
			} else if docking == .dockedToBottom {
				startOrigin = CGPoint(x: frame.origin.x, y: 0 - frame.height)
			}

			setFrameOrigin(startOrigin)
		} else if action == .dismiss {
			if docking == .dockedToTop {
				endFrame.origin = NSPoint(x: frame.origin.x, y: frame.origin.y + frame.height + NSStatusBar.system.thickness)
			} else if docking == .dockedToBottom {
				endFrame.origin = NSPoint(x: frame.origin.x, y: 0 - frame.height)
			}
		}

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			animator().setFrame(endFrame, display: false, animate: true)
		}, completionHandler: {
			if action == .dismiss {
				self.setIsVisible(false)
			}

			self.moveToStartPoint()
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

		// TODO: These could use the `observe` method with `tiedToLifetimeOf` so we don't have to manually invalidate them.
		defaultsObservations.append(Defaults.observe(.windowTransparency) { change in
			self.alphaValue = CGFloat(change.newValue)
		})

		defaultsObservations.append(Defaults.observe(.windowDocking) { change in
			self.docking = change.newValue
		})

		// TODO: We could maybe simplify this by creating another `Default` extension to bind a default to a KeyPath:
		// `defaults.bind(.showOnAllDesktops, to: \.showOnAllDesktop)`
		defaultsObservations.append(Defaults.observe(.showOnAllDesktops) { change in
			self.showOnAllDesktops = change.newValue
		})

		defaultsObservations.append(Defaults.observe(.dockBehavior) { change in
			self.dockBehavior = change.newValue
		})

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
