import Cocoa
import Combine
import Defaults

/**
Convenience function for initializing an object and modifying its properties.

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
	func adding(padding: Double) -> Self {
		Self(
			x: origin.x - CGFloat(padding),
			y: origin.y - CGFloat(padding),
			width: width + CGFloat(padding * 2),
			height: height + CGFloat(padding * 2)
		)
	}

	/**
	Returns a `CGRect` where `self` is centered in `rect`.
	*/
	func centered(in rect: Self, xOffset: Double = 0, yOffset: Double = 0) -> Self {
		Self(
			x: ((rect.width - size.width) / 2) + CGFloat(xOffset),
			y: ((rect.height - size.height) / 2) + CGFloat(yOffset),
			width: size.width,
			height: size.height
		)
	}
}


extension NSWindow {
	var toolbarView: NSView? { standardWindowButton(.closeButton)?.superview }
}


extension NSWindow {
	enum MoveXPositioning {
		case left, center, right
	}

	enum MoveYPositioning {
		case top, center, bottom
	}

	func moveTo(x xPositioning: MoveXPositioning, y yPositioning: MoveYPositioning) {
		guard let screen = NSScreen.main else {
			return
		}

		let visibleFrame = screen.visibleFrame

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
			// Defect fix: keep docked windows below menubar area.
			// Previously, the window would obstruct menubar clicks when the menubar was set to auto-hide.
			// Now, the window stays below that area.
			let menubarThickness = NSStatusBar.system.thickness
			y = min(visibleFrame.maxY - frame.height, screen.frame.maxY - menubarThickness - frame.height)
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
		get { state == .on }
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
			objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T?
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
			(TargetActionSenderAssociatedKeys.trampoline[self] as? ActionTrampoline<Self>)?.action
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
	var isLeftMouseDown: Bool { currentEvent?.type == .leftMouseDown }
	var isOptionKeyDown: Bool { NSEvent.modifierFlags.contains(.option) }
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


extension NSWindow.Level {
	private static func level(for cgLevelKey: CGWindowLevelKey) -> NSWindow.Level {
		NSWindow.Level(rawValue: Int(CGWindowLevelForKey(cgLevelKey)))
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


struct App {
	static let url = Bundle.main.bundleURL

	static func quit() {
		NSApp.terminate(nil)
	}

	static func relaunch() {
		let configuration = NSWorkspace.OpenConfiguration()
		configuration.createsNewApplicationInstance = true

		NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
			DispatchQueue.main.async {
				if let error = error {
					NSApp.presentError(error)
					return
				}

				quit()
			}
		}
	}
}


extension NSScreen {
	// Returns a publisher that sends updates when anything related to screens change.
	// This includes screens being added/removed, resolution change, and the screen frame changing (dock and menu bar being toggled).
	static var publisher: AnyPublisher<Void, Never> {
		Publishers.Merge(
			NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification),
			// We use a wake up notification as the screen setup might have changed during sleep. For example, a screen could have been unplugged.
			NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
		)
			.map { _ in }
			.eraseToAnyPublisher()
	}
}


extension Collection where Element == DefaultsObservation {
	@discardableResult
	func tieAllToLifetime(of weaklyHeldObject: AnyObject) -> Self {
		for observation in self {
			observation.tieToLifetime(of: weaklyHeldObject)
		}
		return self
	}
}

extension Defaults {
	static func tiedToLifetime(of weaklyHeldObject: AnyObject, @ArrayBuilder<DefaultsObservation> _ observations: () -> [DefaultsObservation]) {
		observations().tieAllToLifetime(of: weaklyHeldObject)
	}
}


@_functionBuilder
struct ArrayBuilder<T> {
	static func buildBlock(_ elements: T...) -> [T] { elements }
}


extension NSStatusBarButton {
	private var buttonCell: NSButtonCell? { cell as? NSButtonCell }

	/**
	Whether the status bar button is prevented from (blue) highlighting on click.
	
	The default is `false`.
	
	Can be useful if clicking the status bar button triggers an action instead of opening a menu/popover.
	*/
	var preventsHighlight: Bool {
		get {
			buttonCell?.highlightsBy.isEmpty ?? false
		}
		set {
			buttonCell?.highlightsBy = newValue ? [] : [.changeBackgroundCellMask]
		}
	}
}
