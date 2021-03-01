import SwiftUI
import KeyboardShortcuts

private struct ShortcutRecorder: View {
	var title: String
	var shortcut: KeyboardShortcuts.Name

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text("\(title):")
			KeyboardShortcuts.Recorder(for: shortcut)
		}
	}
}

struct KeyboardShortcutsView: View {
	var body: some View {
		VStack {
			ShortcutRecorder(title: "Toggle Touch Bar", shortcut: .toggleTouchBar)
		}
			.padding(20)
			.fixedSize()
	}
}
