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

extension NSWindow {
	enum MoveXPositioning {
		case left, center, right
	}
	enum MoveYPositioning {
		case top, center, bottom
	}

	func moveTo(x xPositioning: MoveXPositioning, y yPositioning: MoveYPositioning) {
		let visibleFrame = NSScreen.main!.visibleFrame

		let x: CGFloat, y: CGFloat
		switch xPositioning {
		case .left:
			x = visibleFrame.minX
		case .center:
			x = visibleFrame.midX - frame.width / 2
		case .right:
			x = visibleFrame.maxX - frame.width
		}
		switch yPositioning {
		case .top:
			y = visibleFrame.maxY - frame.height
		case .center:
			y = visibleFrame.midY - frame.height / 2
		case .bottom:
			y = visibleFrame.minY
		}

		setFrameOrigin(CGPoint(x: x, y: y))
	}
}

extension NSView {
	func addSubviews(_ subviews: NSView...) {
		subviews.forEach { addSubview($0) }
	}
}

final class AssociatedObject<T: Any> {
	subscript(index: Any) -> T? {
		get {
			return objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T?
		} set {
			objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

@objc
protocol TargetActionSender: AnyObject {
	var target: AnyObject? { get set }
	var action: Selector? { get set }
}

extension NSControl: TargetActionSender {}
extension NSMenuItem: TargetActionSender {}

private final class ActionClosureCaller: NSObject {
	@objc
	fileprivate func callClosure(_ sender: TargetActionSender) {
		onAction?(sender)
	}

	fileprivate var onAction: TargetActionSender.ActionClosure?
}

private struct TargetActionSenderAssociatedKeys {
	fileprivate static let caller = AssociatedObject<ActionClosureCaller>()
}

extension TargetActionSender {
	typealias ActionClosure = ((TargetActionSender) -> Void)

	/**
	Closure version of `.action`

	```
	let menuItem = NSMenuItem(title: "Unicorn")
	menuItem.onAction = { sender in
		print("NSMenuItem action: \(sender)")
	}
	```
	*/
	var onAction: ActionClosure? {
		get {
			return TargetActionSenderAssociatedKeys.caller[self]?.onAction
		}
		set {
			if let caller = TargetActionSenderAssociatedKeys.caller[self] {
				caller.onAction = newValue
				action = #selector(ActionClosureCaller.callClosure)
				target = caller
			} else {
				TargetActionSenderAssociatedKeys.caller[self] = ActionClosureCaller()
				self.onAction = newValue
			}
		}
	}
}

extension NSApplication {
	func leftMouseIsDown() -> Bool {
		return currentEvent?.type == .leftMouseDown
	}

	func optionKeyIsDown() -> Bool {
		return currentEvent?.modifierFlags.contains(.option) ?? false
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
