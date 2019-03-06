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
		guard let visibleFrame = NSScreen.main?.visibleFrame else {
			return
		}

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

extension NSMenuItem {
	var isChecked: Bool {
		get {
			return state == .on
		}
		set {
			state = newValue ? .on : .off
		}
	}
}

extension NSMenuItem {
	convenience init(
		_ title: String,
		keyEquivalent: String = "",
		keyModifiers: NSEvent.ModifierFlags? = nil,
		isChecked: Bool = false,
		action: ((NSMenuItem) -> Void)? = nil
	) {
		self.init(title: title, action: nil, keyEquivalent: keyEquivalent)

		if let keyModifiers = keyModifiers {
			self.keyEquivalentModifierMask = keyModifiers
		}

		self.isChecked = isChecked

		if let action = action {
			self.onAction = action
		}
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
extension NSGestureRecognizer: TargetActionSender {}

private final class ActionTrampoline<Sender>: NSObject {
	typealias ActionClosure = ((Sender) -> Void)

	let action: ActionClosure

	init(action: @escaping ActionClosure) {
		self.action = action
	}

	@objc
	fileprivate func performAction(_ sender: TargetActionSender) {
		action(sender as! Sender)
	}
}

private struct TargetActionSenderAssociatedKeys {
	fileprivate static let trampoline = AssociatedObject<AnyObject>()
}

extension TargetActionSender {
	/**
	Closure version of `.action`.

	```
	let menuItem = NSMenuItem(title: "Unicorn")
	menuItem.onAction = { sender in
		print("NSMenuItem action: \(sender)")
	}
	```
	*/
	var onAction: ((Self) -> Void)? {
		get {
			return (TargetActionSenderAssociatedKeys.trampoline[self] as? ActionTrampoline<Self>)?.action
		}
		set {
			guard let newValue = newValue else {
				target = nil
				action = nil
				TargetActionSenderAssociatedKeys.trampoline[self] = nil
				return
			}

			let trampoline = ActionTrampoline(action: newValue)
			TargetActionSenderAssociatedKeys.trampoline[self] = trampoline
			target = trampoline
			action = #selector(ActionTrampoline<Self>.performAction)
		}
	}

	func addAction(_ action: @escaping ((Self) -> Void)) {
		// TODO: The problem with doing it like this is that there's no way to add ability to remove an action. I think a better solution would be to store an array of action handlers using associated object.
		let lastAction = onAction
		onAction = { sender in
			lastAction?(sender)
			action(sender)
		}
	}
}

extension NSApplication {
	var isLeftMouseDown: Bool {
		return currentEvent?.type == .leftMouseDown
	}

	var isOptionKeyDown: Bool {
		return NSEvent.modifierFlags.contains(.option)
	}
}

// TODO: Find a namespace to put this onto. I don't like free-floating functions.
func pressKey(keyCode: CGKeyCode, flags: CGEventFlags = []) {
	let eventSource = CGEventSource(stateID: .hidSystemState)
	let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true)
	let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false)
	keyDown?.flags = flags
	keyDown?.post(tap: .cghidEventTap)
	keyUp?.post(tap: .cghidEventTap)
}
