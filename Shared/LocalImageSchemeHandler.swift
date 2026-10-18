import Foundation
import UniformTypeIdentifiers
import WebKit

/// Sirve al WebView las imágenes locales que enlaza el Markdown (por ejemplo `docs/icono.png`).
/// El proceso del WebView no puede leer el disco por su cuenta, así que el JavaScript de la página
/// reescribe esas rutas a `vistazo-local:///ruta/absoluta` y esta clase las lee y las entrega.
final class LocalImageSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "vistazo-local"

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        let fileURL = URL(fileURLWithPath: url.path)

        // Solo imágenes: la página no puede usar este esquema para leer otros ficheros.
        guard let type = UTType(filenameExtension: fileURL.pathExtension), type.conforms(to: .image),
              let data = try? Data(contentsOf: fileURL) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = URLResponse(url: url, mimeType: type.preferredMIMEType ?? "application/octet-stream",
                                   expectedContentLength: data.count, textEncodingName: nil)
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

extension WKWebViewConfiguration {
    /// Configuración común del WebView de la app y de la extensión de Quick Look.
    static func markdownViewer() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(LocalImageSchemeHandler(), forURLScheme: LocalImageSchemeHandler.scheme)
        return configuration
    }
}
