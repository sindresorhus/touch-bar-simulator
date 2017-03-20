//
//  AppDelegate.swift
//  Touch Bar Simulator
//
//  Created by Sindre Sorhus on 10/03/2017
//  MIT License © Sindre Sorhus
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
	let controller = IDETouchBarSimulatorHostWindowController.simulatorHostWindowController()!

	func applicationDidFinishLaunching(_ notification: Notification) {
		controller.window?.delegate = self
		addScreenshotButton()
		addTransparencySlider()
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

	func addScreenshotButton() {
		let toolbarView = controller.window!.standardWindowButton(.closeButton)!.superview!
		let button = NSButton()
		button.image = #imageLiteral(resourceName: "ScreenshotButton")
		button.imageScaling = .scaleProportionallyDown
		button.isBordered = false
		button.bezelStyle = .shadowlessSquare
		button.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
		button.action = #selector(captureScreenshot)
		toolbarView.addSubview(button)
	}

	func captureScreenshot() {
		let KEY_6: CGKeyCode = 0x58
		let src = CGEventSource(stateID: .hidSystemState)
		let keyDown = CGEvent(keyboardEventSource: src, virtualKey: KEY_6, keyDown: true)
		let keyUp = CGEvent(keyboardEventSource: src, virtualKey: KEY_6, keyDown: false)
		let loc = CGEventTapLocation.cghidEventTap
		keyDown?.flags = [.maskShift, .maskCommand]
		keyDown?.post(tap: loc)
		keyUp?.post(tap: loc)
	}
	
	func addTransparencySlider() {
		let toolbarView = controller.window!.standardWindowButton(.closeButton)!.superview!
		let slider = ToolbarSlider()
		slider.frame = CGRect(x: toolbarView.frame.width - 150, y: 4, width: 120, height: 11)
		slider.action = #selector(settTransparency)
		toolbarView.addSubview(slider)
		
		var transparency = UserDefaults.standard.double(forKey: "TransparencySlider")
		if transparency == 0 {
			transparency = 0.75
		}
		slider.minValue = 0.5
		slider.doubleValue = transparency
		controller.window!.alphaValue = CGFloat(slider.doubleValue)
	}
	
	func settTransparency(sender : NSSlider) {
		controller.window!.alphaValue = CGFloat(sender.doubleValue)
		UserDefaults.standard.set(sender.doubleValue, forKey: "TransparencySlider")
	}
}

let app = NSApplication.shared()
let delegate = AppDelegate()
app.delegate = delegate
app.run()
