import Cocoa

final class TouchBarWindow: NSPanel {
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
		self.title = "Touch Bar Simulator"
		self.isRestorable = true
		self.hidesOnDeactivate = false
		self.worksWhenModal = true
		self.acceptsMouseMovedEvents = true
		self.isMovableByWindowBackground = false
	}
}
