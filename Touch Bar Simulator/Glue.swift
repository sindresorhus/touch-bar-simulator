import Foundation
import Defaults

// TODO: Upstream all these to https://github.com/sindresorhus/Defaults

extension Defaults {
	@discardableResult
	static func observe<T: Codable, Weak: AnyObject>(
		_ key: Key<T>,
		tiedToLifetimeOf weaklyHeldObject: Weak,
		options: NSKeyValueObservingOptions = [.initial, .new, .old],
		handler: @escaping (KeyChange<T>) -> Void
	) -> DefaultsObservation {
		var observation: DefaultsObservation!
		observation = observe(key, options: options) { [weak weaklyHeldObject] change in
			guard let temporaryStrongReference = weaklyHeldObject else {
				// Will never occur on first call (outer function holds a strong reference),
				// so observation will never be nil
				observation.invalidate()
				return
			}

			_ = temporaryStrongReference
			handler(change)
		}

		return observation
	}
}

extension NSMenuItem {
	/**
	Adds an action to this menu item that toggles the value of `key` in the
	defaults system, and initializes this item's state to the current value of
	`key`.

	```
	let menuItem = NSMenuItem(title: "Invert Colors").bindState(to: .invertColors)
	```
	*/
	func bindState(to key: Defaults.Key<Bool>) -> Self {
		addAction { _ in
			Defaults[key].toggle()
		}

		// swiftlint:disable:next unowned_variable_capture
		Defaults.observe(key, tiedToLifetimeOf: self) { [unowned self] change in
			self.isChecked = change.newValue
		}

		return self
	}

	// TODO: The doc comments here are out of date.
	/**
	Adds an action to this menu item that sets the value of `key` in the
	defaults system to `value`, and initializes this item's state based on
	whether the current value of `key` matches `value`.

	```
	enum BillingType {
		case paper, electronic, duck
	}

	let menuItem = NSMenuItem(title: "Duck").bindChecked(to: .billingType, value: .duck)
	```
	*/
	func bindChecked<Value: Equatable>(to key: Defaults.Key<Value>, value: Value) -> Self {
		addAction { _ in
			Defaults[key] = value
		}

		// swiftlint:disable:next unowned_variable_capture
		Defaults.observe(key, tiedToLifetimeOf: self) { [unowned self] change in
			self.isChecked = (change.newValue == value)
		}

		return self
	}
}

// TODO: Generalize this to all `NSControl`s, or maybe even all things with a `.action` and `.doubleValue`?
extension NSSlider {
	// TODO: The doc comments here are out of date
	/**
	Adds an action to this slider that sets the value of `key` in the defaults
	system to the slider's `doubleValue`, and initializes its value to the
	current value of `key`.

	```
	let slider = NSSlider().bindDoubleValue(to: .transparency)
	```
	*/
	func bindDoubleValue(to key: Defaults.Key<Double>) -> Self {
		addAction { sender in
			Defaults[key] = sender.doubleValue
		}

		// swiftlint:disable:next unowned_variable_capture
		Defaults.observe(key, tiedToLifetimeOf: self) { [unowned self] change in
			self.doubleValue = change.newValue
		}

		return self
	}
}
