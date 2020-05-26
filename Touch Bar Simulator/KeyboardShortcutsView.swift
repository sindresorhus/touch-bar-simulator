import SwiftUI
import KeyboardShortcuts

struct KeyboardShortcutsView: View {
	private struct ShortcutRecorder: SwiftUI.View {
		var title: String
		var shortcut: KeyboardShortcuts.Name
		var body: some View {
			HStack {
				Text(title + ":")
				KeyboardShortcuts.Recorder(for: shortcut)
			}
		}
	}

	var body: some View {
		VStack {
			ShortcutRecorder(title: "Toggle Touch Bar", shortcut: .toggleTouchBar)
		}
		.padding()
		.fixedSize()
	}
}
