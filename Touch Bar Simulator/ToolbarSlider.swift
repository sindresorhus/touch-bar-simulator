//
//  ToolbarSlider.swift
//  Touch Bar Simulator
//
//  Created by Wayne Yeh on 2017/3/20
//  MIT License © Sindre Sorhus
//

import Cocoa

private final class ToolbarSliderCell: NSSliderCell {
	private static let knob: NSImage = {
		let frame = NSRect(x: 0, y: 0, width: 32, height: 32)

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

	override func drawKnob(_ knobRect: NSRect) {
		ToolbarSliderCell.knob.draw(in: knobRect.insetBy(dx: 0, dy: 6.5))
	}
}

final class ToolbarSlider: NSSlider {
	override init(frame: CGRect) {
		super.init(frame: frame)
		cell = ToolbarSliderCell()
	}

	convenience init() {
		self.init(frame: CGRect.zero)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
