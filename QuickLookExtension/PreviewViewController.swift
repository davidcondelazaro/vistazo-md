import Cocoa
import Quartz
import WebKit

/// Vista previa de Quick Look (barra espaciadora en Finder) para ficheros Markdown.
final class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {
    private var webView: WKWebView!
    private var loadContinuation: CheckedContinuation<Void, Never>?

    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700), configuration: .markdownViewer())
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        view = webView
        preferredContentSize = NSSize(width: 900, height: 700)
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let markdown = try MarkdownPage.readText(at: url)
        let html = MarkdownPage.html(markdown: markdown, title: url.lastPathComponent)

        // Esperamos a que el WebView termine de pintar para que Quick Look no muestre un panel en blanco.
        await withCheckedContinuation { continuation in
            loadContinuation = continuation
            webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.finishLoading() }
        }
    }

    private func finishLoading() {
        loadContinuation?.resume()
        loadContinuation = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finishLoading() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finishLoading() }

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
