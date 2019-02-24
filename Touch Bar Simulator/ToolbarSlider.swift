import Cocoa
import Defaults

private final class ToolbarSliderCell: NSSliderCell {
	var fillColor: NSColor
	var borderColor: NSColor
	var shadow: NSShadow?

	init(fillColor: NSColor, borderColor: NSColor, shadow: NSShadow? = nil) {
		self.fillColor = fillColor
		self.borderColor = borderColor
		self.shadow = shadow
		super.init()
	}

	@available(*, unavailable)
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func drawKnob(_ knobRect: CGRect) {
		let frame = knobRect.insetBy(dx: 0, dy: 6.5)

		NSGraphicsContext.saveGraphicsState()

		self.shadow?.set()

		// Circle
		let path = NSBezierPath(roundedRect: frame, xRadius: 4, yRadius: 12)
		self.fillColor.set()
		path.fill()

		// Border should not draw a shadow
		NSShadow().set()

		// Border
		self.borderColor.set()
		path.lineWidth = 0.8
		path.stroke()

		NSGraphicsContext.restoreGraphicsState()
	}
}

extension NSSlider {
	// Redisplaying the slider prevents shadow artifacts that result
	// from moving a knob that draws a shadow
	// However, only do so if its value has changed, because if a
	// redisplay is attempted without a change, then the slider draws
	// itself brighter for some reason
	func alwaysRedisplayOnValueChanged() -> Self {
		self.addAction { sender in
			if (defaults[.windowTransparency] - sender.doubleValue) != 0 {
				sender.needsDisplay = true
			}
		}
		return self
	}
}

final class ToolbarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)

		let knobShadow = NSShadow()
		knobShadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
		knobShadow.shadowOffset = CGSize(width: 0.8, height: -0.8)
		knobShadow.shadowBlurRadius = 5

		self.cell = ToolbarSliderCell(fillColor: NSColor.lightGray, borderColor: .black, shadow: knobShadow)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

final class MenubarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)

		let knobShadow = NSShadow()
		knobShadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
		knobShadow.shadowOffset = CGSize(width: 0.8, height: -0.8)
		knobShadow.shadowBlurRadius = 4

		self.cell = ToolbarSliderCell(fillColor: .controlTextColor, borderColor: .clear, shadow: knobShadow)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
