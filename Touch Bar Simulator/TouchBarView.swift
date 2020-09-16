import Cocoa

final class TouchBarView: NSView {
	private var stream: CGDisplayStream?
	private let displayView = NSView()
	private let initialDFRStatus: Int32

	override init(frame: CGRect) {
		self.initialDFRStatus = DFRGetStatus()

		super.init(frame: .zero)

		wantsLayer = true
		start()
		setFrameSize(DFRGetScreenSize())
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		stop()
	}

	override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

	func start() {
		if (initialDFRStatus & 0x01) == 0 {
			DFRSetStatus(2)
		}

		stream = SLSDFRDisplayStreamCreate(0, .main) { [weak self] status, _, frameSurface, _ in
			guard
				let self = self,
				status == .frameComplete,
				let layer = self.layer
			else {
				return
			}

			layer.contents = frameSurface
		}.takeUnretainedValue()

		stream?.start()
	}

	func stop() {
		guard let stream = stream else {
			return
		}

		stream.stop()
		self.stream = nil
		DFRSetStatus(initialDFRStatus)
	}

	private func mouseEvent(_ event: NSEvent) {
		let location = convert(event.locationInWindow, from: nil)
		DFRFoundationPostEventWithMouseActivity(event.type, location)
	}

	override func mouseDown(with event: NSEvent) {
		mouseEvent(event)
	}

	override func mouseUp(with event: NSEvent) {
		mouseEvent(event)
	}

	override func mouseDragged(with event: NSEvent) {
		mouseEvent(event)
	}
}
