import Foundation
import Defaults

extension NSMenuItem {
	func bindToggle(to key: Defaults.Key<Bool>) -> NSMenuItem {
		let action = self.onAction
		self.onAction = { sender in
			defaults[key] = !defaults[key]
			if let action = action {
				action(sender)
			}
		}
		self.state = defaults[key] ? .on : .off
		return self
	}

	func bindActivation<Value: Equatable>(to key: Defaults.Key<Value>, value: Value) -> NSMenuItem {
		let action = self.onAction
		self.onAction = { sender in
			defaults[key] = value
			if let action = action {
				action(sender)
			}
		}
		self.state = defaults[key] == value ? .on : .off
		return self
	}
}
