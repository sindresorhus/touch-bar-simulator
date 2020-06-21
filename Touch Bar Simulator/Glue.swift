import AppKit
import Defaults

// TODO: Upstream all these to https://github.com/sindresorhus/Defaults

extension NSMenuItem {
	/**
	Adds an action to this menu item that toggles the value of `key` in the
	defaults system, and initializes this item's state to the current value of
	`key`.

	```
	let menuItem = NSMenuItem(title: "Invert Colors").bindState(to: .invertColors)
	```
	*/
	@discardableResult
	func bindState(to key: Defaults.Key<Bool>) -> Self {
		addAction { _ in
			Defaults[key].toggle()
		}

		Defaults.observe(key) { [weak self] change in
			self?.isChecked = change.newValue
		}
			.tieToLifetime(of: self)

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
	@discardableResult
	func bindChecked<Value: Equatable>(to key: Defaults.Key<Value>, value: Value) -> Self {
		addAction { _ in
			Defaults[key] = value
		}

		Defaults.observe(key) { [weak self] change in
			self?.isChecked = (change.newValue == value)
		}
			.tieToLifetime(of: self)

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
	@discardableResult
	func bindDoubleValue(to key: Defaults.Key<Double>) -> Self {
		addAction { sender in
			Defaults[key] = sender.doubleValue
		}

		Defaults.observe(key) { [weak self] change in
			self?.doubleValue = change.newValue
		}
			.tieToLifetime(of: self)

		return self
	}
}
