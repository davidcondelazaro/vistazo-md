import Cocoa
import WebKit

/// Una ventana por fichero Markdown. Se vuelve a pintar sola cuando el fichero cambia.
final class DocumentWindowController: NSWindowController, NSWindowDelegate, WKNavigationDelegate {
    let fileURL: URL
    var onClose: ((DocumentWindowController) -> Void)?

    private let webView: WKWebView
    private var watcher: FileWatcher?
    private var pageReady = false
    private var lastMarkdown: String?

    init(fileURL: URL) {
        self.fileURL = fileURL
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 800), configuration: .markdownViewer())
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = true

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 800),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = fileURL.lastPathComponent
        window.representedURL = fileURL
        window.contentView = webView
        window.tabbingIdentifier = "VistazoMD"
        window.minSize = NSSize(width: 360, height: 240)
        super.init(window: window)

        window.delegate = self
        webView.navigationDelegate = self
        loadPage()
        watcher = FileWatcher(url: fileURL) { [weak self] in self?.refresh() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    private func readMarkdown() -> String {
        do {
            return try MarkdownPage.readText(at: fileURL)
        } catch {
            return "> ⚠️ No se puede leer **\(fileURL.lastPathComponent)**: \(error.localizedDescription)"
        }
    }

    private func loadPage() {
        let markdown = readMarkdown()
        lastMarkdown = markdown
        pageReady = false
        webView.loadHTMLString(MarkdownPage.html(markdown: markdown, title: fileURL.lastPathComponent),
                               baseURL: fileURL.deletingLastPathComponent())
    }

    /// Vuelve a pintar el contenido sin recargar la página, conservando el scroll.
    private func refresh() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        let markdown = readMarkdown()
        guard markdown != lastMarkdown else { return }
        lastMarkdown = markdown
        guard pageReady else { return loadPage() }
        webView.evaluateJavaScript(MarkdownPage.rerenderScript(markdown: markdown))
    }

    // MARK: Menú Visualización

    @objc func reloadDocument(_ sender: Any?) { loadPage() }
    @objc func zoomIn(_ sender: Any?) { webView.pageZoom = min(webView.pageZoom + 0.1, 3) }
    @objc func zoomOut(_ sender: Any?) { webView.pageZoom = max(webView.pageZoom - 0.1, 0.5) }
    @objc func actualSize(_ sender: Any?) { webView.pageZoom = 1 }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        watcher?.stop()
        watcher = nil
        onClose?(self)
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { pageReady = true }

    // Los enlaces externos se abren en el navegador; los anclas internos se resuelven dentro.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated, let target = action.request.url else {
            decisionHandler(.allow)
            return
        }
        if target.fragment != nil, target.scheme == "file" || target.scheme == "about" {
            decisionHandler(.allow)
            return
        }
        NSWorkspace.shared.open(target)
        decisionHandler(.cancel)
    }
}
