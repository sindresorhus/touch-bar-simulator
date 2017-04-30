//
//  AppDelegate.swift
//  Touch Bar Simulator
//
//  Created by Sindre Sorhus on 10/03/2017
//  MIT License © Sindre Sorhus
//

import Cocoa
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
	let controller = IDETouchBarSimulatorHostWindowController.simulatorHostWindowController()!
	var toolbarView: NSView!

	func applicationDidFinishLaunching(_ notification: Notification) {
		_ = SUUpdater()

		controller.window?.delegate = self
		toolbarView = controller.window!.standardWindowButton(.closeButton)!.superview!
		addScreenshotButton()
		addTransparencySlider()
		NSApp.servicesProvider = self
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

	func addScreenshotButton() {
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
		let slider = ToolbarSlider()
		slider.frame = CGRect(x: toolbarView.frame.width - 150, y: 4, width: 120, height: 11)
		slider.action = #selector(setTransparency)
		toolbarView.addSubview(slider)

		var transparency = UserDefaults.standard.double(forKey: "windowTransparency")
		if transparency == 0 {
			transparency = 0.75
		}
		slider.minValue = 0.5
		slider.doubleValue = transparency
		controller.window!.alphaValue = CGFloat(slider.doubleValue)
	}

	func setTransparency(sender: NSSlider) {
		controller.window!.alphaValue = CGFloat(sender.doubleValue)
		UserDefaults.standard.set(sender.doubleValue, forKey: "windowTransparency")
	}
}

let app = NSApplication.shared()
let delegate = AppDelegate()
app.delegate = delegate
app.run()
