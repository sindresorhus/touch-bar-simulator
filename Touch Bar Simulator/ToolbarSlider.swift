import Cocoa

private let knob: NSImage = {
	let frame = CGRect(x: 0, y: 0, width: 32, height: 32)

	let image = NSImage(size: frame.size)
	image.lockFocus()

	// Circle
	let path = NSBezierPath(roundedRect: frame, xRadius: 4, yRadius: 12)
	NSColor.lightGray.set()
	path.fill()

	// Border
	NSColor.black.set()
	path.lineWidth = 2
	path.stroke()

	image.unlockFocus()
	return image
}()

private final class ToolbarSliderCell: NSSliderCell {
	override func drawKnob(_ knobRect: CGRect) {
		knob.draw(in: knobRect.insetBy(dx: 0, dy: 6.5))
	}
}

final class ToolbarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)
		cell = ToolbarSliderCell()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
