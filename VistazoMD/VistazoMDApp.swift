import SwiftUI
import UniformTypeIdentifiers
import WebKit

@main
struct VistazoMDApp: App {
    var body: some Scene {
        WindowGroup("Vistazo MD") {
            ContentView()
                .frame(minWidth: 640, minHeight: 480)
        }
        .windowResizability(.contentMinSize)
    }
}

/// La app existe sobre todo para "transportar" la extensión de Quick Look,
/// pero también sirve de visor: abre o arrastra un .md y lo verás con el mismo renderizado.
struct ContentView: View {
    @State private var fileURL: URL?
    @State private var html: String?
    @State private var isTargeted = false

    var body: some View {
        Group {
            if let html {
                MarkdownWebView(html: html, baseURL: fileURL?.deletingLastPathComponent())
            } else {
                welcome
            }
        }
        .navigationTitle(fileURL?.lastPathComponent ?? "Vistazo MD")
        .toolbar {
            ToolbarItem {
                Button("Abrir…", systemImage: "doc.text", action: openPanel)
                    .keyboardShortcut("o")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { DispatchQueue.main.async { load(url) } }
            }
            return true
        }
    }

    private var welcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Vista rápida de Markdown instalada")
                .font(.title2.bold())
            Text("Selecciona un fichero .md en Finder y pulsa la barra espaciadora.\nTambién puedes arrastrar uno aquí o pulsar ⌘O.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Ajustes de extensiones de Quick Look…") {
                let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.quicklook.preview")!
                NSWorkspace.shared.open(url)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.08) : .clear)
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = MarkdownPage.fileExtensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { load(url) }
    }

    private func load(_ url: URL) {
        guard let text = try? MarkdownPage.readText(at: url) else { return }
        fileURL = url
        html = MarkdownPage.html(markdown: text, title: url.lastPathComponent)
    }
}

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: baseURL)
    }
}
