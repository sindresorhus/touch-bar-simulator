import Foundation
import Defaults

struct Constants {
	static let windowAutosaveName = "TouchBarWindow"
}

extension Defaults.Keys {
	static let windowTransparency = Key<Double>("windowTransparency", default: 0.75)
	static let windowDocking = Key<TouchBarWindow.Docking>("windowDocking", default: .floating)
	static let showOnAllDesktops = Key<Bool>("showOnAllDesktops", default: false)
	static let lastFloatingPos = OptionalKey<CGPoint>("lastFloatingPos")
}
