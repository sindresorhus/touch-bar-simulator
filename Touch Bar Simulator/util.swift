import Cocoa

extension NSWindow {
	var toolbarView: NSView? {
		return standardWindowButton(.closeButton)?.superview
	}
}

extension NSView {
	func addSubviews(_ subviews: NSView...) {
		subviews.forEach { addSubview($0) }
	}
}

func pressKey(keyCode: CGKeyCode, flags: CGEventFlags = []) {
	let eventSource = CGEventSource(stateID: .hidSystemState)
	let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true)
	let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false)
	keyDown?.flags = flags
	keyDown?.post(tap: .cghidEventTap)
	keyUp?.post(tap: .cghidEventTap)
}
