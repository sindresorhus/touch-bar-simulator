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

	var dockBehaviorTimer = Timer()
	var showTouchBarTimer = Timer()

	func startDockBehaviorTimer() {
		stopDockBehaviorTimer()
		dockBehaviorTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleDockBehavior), userInfo: nil, repeats: true)
	}

	func stopDockBehaviorTimer() {
		dockBehaviorTimer.invalidate()
		dockBehaviorTimer = Timer()
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
		guard self.docking != nil,
			let visibleFrame = NSScreen.main?.visibleFrame,
			let screenFrame = NSScreen.main?.frame else {
			return
		}
		var detectionRect: NSRect = .zero
		if self.docking! == .dockedToBottom {
			if self.isVisible {
				detectionRect = NSRect(x: 0, y: 0, width: visibleFrame.width, height: self.frame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness))
			} else {
				detectionRect = NSRect(x: 0, y: 0, width: visibleFrame.width, height: 1)
			}
		} else if self.docking! == .dockedToTop {
			if self.isVisible {
				detectionRect = NSRect(
					x: 0,
					// without `+ 1` the touch bar would glitch (toggling rapidly).
					y: screenFrame.height - self.frame.height - NSStatusBar.system.thickness + 1,
					width: visibleFrame.width,
					height: self.frame.height + NSStatusBar.system.thickness)
			} else {
				detectionRect = NSRect(
					x: 0,
					y: screenFrame.height,
					width: visibleFrame.width,
					height: 1)
			}
		}
		let mouseLocation = NSEvent.mouseLocation
		if detectionRect.contains(mouseLocation) {
			dismissAnimationDidRun = false
			guard !showTouchBarTimer.isValid && !showAnimationDidRun else {
				return
			}
			showTouchBarTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
				self.showTouchBarWithAnimation()
				self.showAnimationDidRun = true
			})
		} else {
			showTouchBarTimer.invalidate()
			showTouchBarTimer = Timer()
			showAnimationDidRun = false
			if self.isVisible && !dismissAnimationDidRun {
				dismissTouchBarWithAnimation()
				dismissAnimationDidRun = true
			}
		}
	}

	func moveToStartPoint() {
		guard self.docking != nil else {
			return
		}
		if self.docking! == .dockedToTop {
			self.moveTo(x: .center, y: .top)
		} else if self.docking! == .dockedToBottom {
			self.moveTo(x: .center, y: .bottom)
		}
	}

	var showAnimationDidRun = false
	var dismissAnimationDidRun = false

	func showTouchBarWithAnimation() {
		guard self.docking != nil &&
			self.docking! == .dockedToTop ||
			self.docking! == .dockedToBottom else {
			return
		}
		var startOrigin: NSPoint!
		let endFrame = self.frame
		self.setIsVisible(true)
		if self.docking! == .dockedToTop {
			startOrigin = NSPoint(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height)
		} else if self.docking! == .dockedToBottom {
			startOrigin = NSPoint(x: self.frame.origin.x, y: 0 - self.frame.height)
		}
		self.setFrameOrigin(startOrigin)
		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			self.animator().setFrame(endFrame, display: false, animate: true)
			}, completionHandler: {
				self.moveToStartPoint()
		})
	}

	func dismissTouchBarWithAnimation() {
		guard self.docking != nil &&
			self.docking! == .dockedToTop ||
			self.docking! == .dockedToBottom else {
				return
		}
		var endFrame = self.frame
		if self.docking! == .dockedToTop {
			endFrame.origin = NSPoint(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height + NSStatusBar.system.thickness)
		} else if self.docking! == .dockedToBottom {
			endFrame.origin = NSPoint(x: self.frame.origin.x, y: 0 - self.frame.height)
		}
		NSAnimationContext.runAnimationGroup({ context in
			context.duration = TimeInterval(0.3)
			self.animator().setFrame(endFrame, display: false, animate: true)
		}, completionHandler: {
			self.setIsVisible(false)
			self.moveToStartPoint()
		})
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
