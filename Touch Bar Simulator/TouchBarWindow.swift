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

		center()
		setFrameOrigin(CGPoint(x: frame.origin.x, y: 100))

		setFrameUsingName(Constants.windowAutosaveName)
		setFrameAutosaveName(Constants.windowAutosaveName)

		orderFront(nil)
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
				.hudWindow,
				.nonactivatingPanel
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

extension NSWindow.Level {
	private static func level(for cgLevelKey: CGWindowLevelKey) -> NSWindow.Level {
		return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(cgLevelKey)))
	}

	public static let desktop = level(for: .desktopWindow)
	public static let desktopIcon = level(for: .desktopIconWindow)
	public static let backstopMenu = level(for: .backstopMenu)
	public static let dragging = level(for: .draggingWindow)
	public static let overlay = level(for: .overlayWindow)
	public static let help = level(for: .helpWindow)
	public static let utility = level(for: .utilityWindow)
	public static let assistiveTechHigh = level(for: .assistiveTechHighWindow)
	public static let cursor = level(for: .cursorWindow)

	public static let minimum = level(for: .minimumWindow)
	public static let maximum = level(for: .maximumWindow)
}
