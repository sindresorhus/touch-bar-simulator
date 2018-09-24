import Cocoa

/**
Convenience function for initializing an object and modifying its properties

```
let label = with(NSTextField()) {
	$0.stringValue = "Foo"
	$0.textColor = .systemBlue
	view.addSubview($0)
}
```
*/
@discardableResult
func with<T>(_ item: T, update: (inout T) throws -> Void) rethrows -> T {
	var this = item
	try update(&this)
	return this
}

extension CGRect {
	func adding(padding: Double) -> CGRect {
		return CGRect(
			x: origin.x - CGFloat(padding),
			y: origin.y - CGFloat(padding),
			width: width + CGFloat(padding * 2),
			height: height + CGFloat(padding * 2)
		)
	}

	/**
	Returns a CGRect where `self` is centered in `rect`
	*/
	func centered(in rect: CGRect, xOffset: Double = 0, yOffset: Double = 0) -> CGRect {
		return CGRect(
			x: ((rect.width - size.width) / 2) + CGFloat(xOffset),
			y: ((rect.height - size.height) / 2) + CGFloat(yOffset),
			width: size.width,
			height: size.height
		)
	}
}

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
