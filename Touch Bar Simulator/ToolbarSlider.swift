//
//  ToolbarSlider.swift
//  Touch Bar Simulator
//
//  Created by Wayne Yeh on 2017/3/17.
//  Copyright © 2017年 Sindre Sorhus. All rights reserved.
//

import Cocoa

class ToolbarSliderCell: NSSliderCell {
	override func drawKnob(_ knobRect: NSRect) {
		var frame = knobRect.insetBy(dx: 0, dy: 5)
		frame.origin = CGPoint(x: 0, y: 0)
		let image = NSImage(size: frame.size)
		image.lockFocus()
		NSColor.white.set()
		let path = NSBezierPath(roundedRect: frame, xRadius: 3, yRadius: 3)
		NSColor.lightGray.set()
		path.fill()
		NSColor.black.set()
		path.lineWidth = 2
		path.stroke()
		image.unlockFocus()
		
		image.draw(in: knobRect.insetBy(dx: 0, dy: 7))
	}
}

class ToolbarSlider: NSSlider {
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.cell = ToolbarSliderCell()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
