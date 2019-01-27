import Cocoa
import Defaults

private let windowTitle = "Touch Bar Simulator"

final class TouchBarWindow: NSPanel {
	enum Docking: String, Codable {
		case floating, dockedToTop, dockedToBottom

		func dock(window: TouchBarWindow) {
			switch self {
			case .floating:
				window.styleMask.insert(.titled)
				window.becameTitled()
				if let prevPosition = defaults[.lastFloatingPosition] {
					window.setFrameOrigin(prevPosition)
				}
			case .dockedToTop:
				window.styleMask.remove(.titled)
				window.moveTo(x: .center, y: .top)
			case .dockedToBottom:
				window.styleMask.remove(.titled)
				window.moveTo(x: .center, y: .bottom)
			}
		}
	}

	var docking: Docking? {
		didSet {
			if oldValue == .floating && docking != .floating {
				defaults[.lastFloatingPosition] = frame.origin
			}

			docking?.dock(window: self)

			setIsVisible(true)
			orderFront(nil)
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

	func becameTitled() {
		title = windowTitle
		guard let toolbarView = self.toolbarView else {
			return
		}
		toolbarView.addSubviews(
			makeScreenshotButton(toolbarView),
			makeTransparencySlider(toolbarView)
		)
	}

	func makeScreenshotButton(_ toolbarView: NSView) -> NSButton {
		let button = NSButton()
		button.image = #imageLiteral(resourceName: "ScreenshotButton")
		button.imageScaling = .scaleProportionallyDown
		button.isBordered = false
		button.bezelStyle = .shadowlessSquare
		button.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
		button.action = #selector(AppDelegate.captureScreenshot)
		return button
	}

	private var transparencySliders: [ToolbarSlider] = []

	func makeTransparencySlider(_ parentView: NSView) -> ToolbarSlider {
		let slider = ToolbarSlider()
		slider.frame = CGRect(x: parentView.frame.width - 150, y: 4, width: 120, height: 11)
		slider.action = #selector(setTransparency)
		slider.minValue = 0.5
		slider.doubleValue = defaults[.windowTransparency]
		transparencySliders.append(slider)
		return slider
	}

	@objc
	func setTransparency(sender: ToolbarSlider) {
		self.alphaValue = CGFloat(sender.doubleValue)
		defaults[.windowTransparency] = sender.doubleValue
		for slider in transparencySliders where slider !== sender {
			slider.doubleValue = sender.doubleValue
		}
	}

	override var canBecomeMain: Bool {
		return false
	}

	override var canBecomeKey: Bool {
		return false
	}

	func setUp() {
		let view = self.contentView!
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.black.cgColor

		let touchBarView = TouchBarView()
		self.setContentSize(touchBarView.bounds.adding(padding: 5).size)
		touchBarView.frame = touchBarView.frame.centered(in: view.bounds)
		view.addSubview(touchBarView)

		self.center()
		self.setFrameOrigin(CGPoint(x: self.frame.origin.x, y: 100))

		self.setFrameUsingName(Constants.windowAutosaveName)
		self.setFrameAutosaveName(Constants.windowAutosaveName)

		self.orderFront(nil)
	}

	private var defaultsObservations: [DefaultsObservation] = []

	convenience init() {
		self.init(
			contentRect: .zero,
			styleMask: [
				.titled,
				.closable,
				.hudWindow,
				.nonactivatingPanel
			],
			backing: .buffered,
			defer: false
		)

		self._setPreventsActivation(true)
		self.title = windowTitle
		self.isRestorable = true
		self.hidesOnDeactivate = false
		self.worksWhenModal = true
		self.acceptsMouseMovedEvents = true
		self.isMovableByWindowBackground = false

		defaultsObservations.append(defaults.observe(.windowDocking) { change in
			self.docking = change.newValue
		})
		defaultsObservations.append(defaults.observe(.showOnAllDesktops) { change in
			self.showOnAllDesktops = change.newValue
		})
	}

	deinit {
		for observation in defaultsObservations {
			observation.invalidate()
		}
	}
}
