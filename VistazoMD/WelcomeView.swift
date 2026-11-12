import SwiftUI
import UniformTypeIdentifiers

/// Ventana que aparece al abrir la app sin ficheros.
struct WelcomeView: View {
    let openFile: () -> Void
    let openURL: (URL) -> Void

    @State private var defaultViewer = DefaultViewer.current()
    @State private var errorMessage: String?
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text(verbatim: "Vistazo MD")
                .font(.title.bold())
            Text("Select a .md file in Finder and press the space bar to preview it instantly, or double-click to open it.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open a Markdown File…", action: openFile)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)

            Divider().padding(.vertical, 6)

            defaultViewerSection

            Button("Quick Look Extension Settings…") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.quicklook.preview")!)
            }
            .buttonStyle(.link)
        }
        .padding(32)
        .frame(width: 440)
        .background(isTargeted ? Color.accentColor.opacity(0.08) : .clear)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url { DispatchQueue.main.async { openURL(url) } }
                }
            }
            return true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            defaultViewer = DefaultViewer.current()
        }
    }

    @ViewBuilder private var defaultViewerSection: some View {
        if defaultViewer.isThisApp {
            Label("Vistazo MD is your default Markdown viewer", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            VStack(spacing: 8) {
                Text(".md files currently open with **\(defaultViewer.name)**.")
                    .foregroundStyle(.secondary)
                Button("Use Vistazo MD as Default Viewer") {
                    Task {
                        do {
                            try await DefaultViewer.makeThisAppDefault()
                            defaultViewer = DefaultViewer.current()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        if let errorMessage {
            Text(errorMessage).font(.caption).foregroundStyle(.red)
        }
    }
}

/// Consulta y cambia la app que abre los ficheros Markdown al hacer doble clic.
struct DefaultViewer {
    let name: String
    let isThisApp: Bool

    private static let markdown = UTType("net.daringfireball.markdown") ?? UTType(filenameExtension: "md")!

    static func current() -> DefaultViewer {
        guard let url = NSWorkspace.shared.urlForApplication(toOpen: markdown) else {
            return DefaultViewer(name: String(localized: "no app"), isThisApp: false)
        }
        let isThisApp = Bundle(url: url)?.bundleIdentifier == Bundle.main.bundleIdentifier
        return DefaultViewer(name: FileManager.default.displayName(atPath: url.path)
                                .replacingOccurrences(of: ".app", with: ""),
                             isThisApp: isThisApp)
    }

    static func makeThisAppDefault() async throws {
        try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: markdown)
    }
}
