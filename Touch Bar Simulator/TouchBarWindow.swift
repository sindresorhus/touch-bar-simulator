import Cocoa
import Defaults

private let windowTitle = "Touch Bar Simulator"

final class TouchBarWindow: NSPanel {
	enum Docking: String, Codable {
		case floating, dockedToTop, dockedToBottom
	}

	var docking: Docking = .floating {
		didSet {
			switch docking {
			case .floating:
				styleMask.insert(.titled)
				becameTitled()
			case .dockedToTop:
				styleMask.remove(.titled)
				setFrameOrigin(NSPoint(x: NSScreen.main!.visibleFrame.width / 2 - frame.width / 2, y: NSScreen.main!.visibleFrame.maxY - frame.height))
			case .dockedToBottom:
				styleMask.remove(.titled)
				setFrameOrigin(NSPoint(x: NSScreen.main!.visibleFrame.width / 2 - frame.width / 2, y: NSScreen.main!.visibleFrame.minY))
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

	func makeTransparencySlider(_ toolbarView: NSView) -> ToolbarSlider {
		let slider = ToolbarSlider()
		slider.frame = CGRect(x: toolbarView.frame.width - 150, y: 4, width: 120, height: 11)
		slider.action = #selector(setTransparency)
		slider.minValue = 0.5
		slider.doubleValue = defaults[.windowTransparency]
		return slider
	}

	@objc
	func setTransparency(sender: ToolbarSlider) {
		self.alphaValue = CGFloat(sender.doubleValue)
		defaults[.windowTransparency] = sender.doubleValue
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

	override var canBecomeMain: Bool {
		return false
	}

	override var canBecomeKey: Bool {
		return false
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

		self._setPreventsActivation(true)
		self.title = windowTitle
		self.isRestorable = true
		self.hidesOnDeactivate = false
		self.worksWhenModal = true
		self.acceptsMouseMovedEvents = true
		self.isMovableByWindowBackground = false
	}
}
