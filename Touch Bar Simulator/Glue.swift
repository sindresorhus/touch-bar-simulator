import Foundation
import Defaults

extension NSMenuItem {
	/**
	Adds an action to this menu item that toggles the value of `key` in the
	defaults system, and initializes this item's state to the current value of
	`key`.
	
	```
	let menuItem = NSMenuItem(title: "Invert Colors").bindToggle(to: .invertColors)
	```
	*/
	func bindToggle(to key: Defaults.Key<Bool>) -> NSMenuItem {
		let action = self.onAction
		self.onAction = { sender in
			defaults[key].toggle()
			action?(sender)
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
	let menuItem = NSMenuItem(title: "Duck").bindChoice(to: .billingType, value: .duck)
	```
	*/
	func bindChoice<Value: Equatable>(to key: Defaults.Key<Value>, value: Value) -> NSMenuItem {
		let action = self.onAction
		self.onAction = { sender in
			defaults[key] = value
			action?(sender)
		}
		self.isChecked = (defaults[key] == value)
		return self
	}
}
