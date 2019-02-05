import Cocoa

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

		// Border
		self.borderColor.set()
		path.lineWidth = 2
		path.stroke()

		NSGraphicsContext.restoreGraphicsState()
	}
}

final class ToolbarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.cell = ToolbarSliderCell(fillColor: .lightGray, borderColor: .black)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

final class MenubarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)

		let accentColor = NSColor.controlAccentColor.withAlphaComponent(1.0)
		let dimmedAccentColor = accentColor.blended(withFraction: 0.35, of: .black) ?? accentColor

		let knobShadow = NSShadow()
		knobShadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
		knobShadow.shadowOffset = CGSize(width: 0.8, height: -0.8)
		knobShadow.shadowBlurRadius = 4

		self.cell = ToolbarSliderCell(fillColor: dimmedAccentColor, borderColor: .clear, shadow: knobShadow)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
