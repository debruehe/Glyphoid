import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @FocusState private var isGridFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            Divider()

            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("Suchen…", text: $state.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onSubmit { isGridFocused = true }
                    if !state.searchQuery.isEmpty {
                        Button(action: { state.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(.controlBackgroundColor))
                .overlay(Divider(), alignment: .bottom)

                GlyphGridView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusable()
                    .focused($isGridFocused)
                    .onTapGesture { isGridFocused = true }
                    .onKeyPress(.leftArrow)  { state.navigateGrid(direction: .left);  return .handled }
                    .onKeyPress(.rightArrow) { state.navigateGrid(direction: .right); return .handled }
                    .onKeyPress(.upArrow)    { state.navigateGrid(direction: .up);    return .handled }
                    .onKeyPress(.downArrow)  { state.navigateGrid(direction: .down);  return .handled }
                    .onKeyPress(.return) {
                        if let g = state.selectedGlyph { state.insertGlyph(g) }
                        return .handled
                    }
                    .onKeyPress(.space) {
                        if let g = state.selectedGlyph { state.insertGlyph(g) }
                        return .handled
                    }

                GlyphStatusBarView()
            }
        }
        .frame(minWidth: 480, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    state.windowManager.toggle()
                    state.windowStateStore.isPinned = state.windowManager.isPinned
                    state.persistState()
                }) {
                    Image(systemName: state.windowStateStore.isPinned ? "pin.fill" : "pin")
                        .help(state.windowStateStore.isPinned ? "Fenster lösen" : "Fenster anheften")
                }
            }
        }
        .sheet(isPresented: $state.showPermissionSheet) {
            AccessibilityPermissionView()
        }
        .sheet(isPresented: $state.showAboutDialog) {
            AboutView()
        }
        .animation(.easeInOut(duration: 0.15), value: state.toastMessage)
        // Keyboard shortcuts for SVG copy — only active when glyph is selected
        .overlay(
            Group {
                if let glyph = state.selectedGlyph {
                    Button("") { state.copyVectorSVG(for: glyph) }
                        .keyboardShortcut("c", modifiers: .command)
                        .opacity(0)
                    Button("") { state.copyTextSVG(for: glyph) }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                        .opacity(0)
                }
            }
        )
    }
}
