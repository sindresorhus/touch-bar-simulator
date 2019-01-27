import Cocoa

private func makeKnob(fillColor: NSColor, borderColor: NSColor) -> NSImage {
	let frame = CGRect(x: 0, y: 0, width: 32, height: 32)

	let image = NSImage(size: frame.size)
	image.lockFocus()

	// Circle
	let path = NSBezierPath(roundedRect: frame, xRadius: 4, yRadius: 12)
	fillColor.set()
	path.fill()

	// Border
	borderColor.set()
	path.lineWidth = 2
	path.stroke()

	image.unlockFocus()
	return image
}

private final class ToolbarSliderCell: NSSliderCell {
	var knob: NSImage

	init(knob: NSImage) {
		self.knob = knob
		super.init()
	}

	@available(*, unavailable)
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func drawKnob(_ knobRect: CGRect) {
		knob.draw(in: knobRect.insetBy(dx: 0, dy: 6.5))
	}
}

final class ToolbarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)
		cell = ToolbarSliderCell(knob: makeKnob(fillColor: .lightGray, borderColor: .black))
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

final class MenubarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)
		cell = ToolbarSliderCell(knob: makeKnob(fillColor: NSColor.controlTextColor.withAlphaComponent(1.0), borderColor: .systemGray))
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
