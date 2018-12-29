import Cocoa

private let windowTitle = "Touch Bar Simulator"

final class TouchBarWindow: NSPanel {
	enum Docking: String {
		case floating, dockedToTop, dockedToBottom
	}

	var docking: Docking = .floating {
		didSet {
			switch docking {
			case .floating:
				styleMask.insert(.titled)
				title = windowTitle
			case .dockedToTop:
				styleMask.remove(.titled)
				setFrameOrigin(NSPoint(x: NSScreen.main!.visibleFrame.width / 2 - frame.width / 2, y: NSScreen.main!.visibleFrame.maxY - frame.height))
			case .dockedToBottom:
				styleMask.remove(.titled)
				setFrameOrigin(NSPoint(x: NSScreen.main!.visibleFrame.width / 2 - frame.width / 2, y: NSScreen.main!.visibleFrame.minY))
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
