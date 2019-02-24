import Foundation
import Defaults

extension NSMenuItem {
	/**
	Adds an action to this menu item that toggles the value of `key` in the
	defaults system, and initializes this item's state to the current value of
	`key`.

	```
	let menuItem = NSMenuItem(title: "Invert Colors").streamState(to: .invertColors)
	```
	*/
	func streamState(to key: Defaults.Key<Bool>) -> Self {
		self.addAction { _ in
			defaults[key].toggle()
		}
		self.isChecked = defaults[key]
		return self
	}

	/**
	Adds an action to this menu item that sets the value of `key` in the
	defaults system to `value`, and initializes this item's state based on
	whether the current value of `key` matches `value`.

	```
	enum BillingType {
		case paper, electronic, duck
	}
	let menuItem = NSMenuItem(title: "Duck").streamChoice(to: .billingType, value: .duck)
	```
	*/
	func streamChoice<Value: Equatable>(to key: Defaults.Key<Value>, value: Value) -> Self {
		self.addAction { _ in
			defaults[key] = value
		}
		self.isChecked = (defaults[key] == value)
		return self
	}
}

extension NSSlider {
	/**
	Adds an action to this slider that sets the value of `key` in the defaults
	system to the slider's `doubleValue`, and initializes its value to the
	current value of `key`.

	```
	let slider = NSSlider().streamDoubleValue(to: .transparency)
	```
	*/
	func streamDoubleValue(to key: Defaults.Key<Double>) -> Self {
		self.addAction { sender in
			defaults[key] = sender.doubleValue
		}
		self.doubleValue = defaults[key]
		return self
	}
}
