import Foundation

/// Construye una página HTML autocontenida que renderiza Markdown en el propio WebView
/// (marked + DOMPurify + highlight.js), con estilo GitHub y modo claro/oscuro automático.
enum MarkdownPage {
    /// Extensiones que tratamos como Markdown (la app contenedora las usa para filtrar).
    static let fileExtensions = ["md", "markdown", "mdown", "mkd", "mkdn", "mdwn", "mdtxt", "mdtext", "rmd", "qmd"]

    /// Lee el fichero probando UTF-8 y, si falla, otras codificaciones habituales.
    static func readText(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        if let text = String(data: data, encoding: .utf8) { return text }
        if let text = String(data: data, encoding: .isoLatin1) { return text }
        return String(decoding: data, as: UTF8.self)
    }

    static func html(markdown: String, title: String) -> String {
        let source = Data(markdown.utf8).base64EncodedString()
        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="color-scheme" content="light dark">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: file: https: http:; font-src data:;">
        <title>\(escape(title))</title>
        <style>\(resource("github-markdown.css"))</style>
        <style>@media (prefers-color-scheme: light) { \(resource("hljs-github.css")) }</style>
        <style>@media (prefers-color-scheme: dark) { \(resource("hljs-github-dark.css")) }</style>
        <style>
          html, body { margin: 0; background: Canvas; }
          .markdown-body { box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 32px 40px 48px; background: transparent; }
          .markdown-body pre code.hljs { padding: 0; background: transparent; }
          .markdown-body input[type=checkbox] { margin: 0 .35em .2em -1.4em; vertical-align: middle; }
          .frontmatter { font-size: 12px; opacity: .75; }
          @media (max-width: 600px) { .markdown-body { padding: 16px; } }
        </style>
        <script>\(resource("marked.min.js"))</script>
        <script>\(resource("purify.min.js"))</script>
        <script>\(resource("highlight.min.js"))</script>
        </head>
        <body>
        <article id="content" class="markdown-body"></article>
        <script>
        (function () {
          const bytes = Uint8Array.from(atob("\(source)"), c => c.charCodeAt(0));
          let md = new TextDecoder("utf-8").decode(bytes);

          // Front matter YAML (---) al principio: lo mostramos como bloque de código discreto.
          let front = "";
          const fm = md.match(/^---\\r?\\n([\\s\\S]*?)\\r?\\n(---|\\.\\.\\.)\\r?\\n/);
          if (fm) { front = fm[1]; md = md.slice(fm[0].length); }

          marked.setOptions({ gfm: true, breaks: false });
          let html = marked.parse(md);
          if (front) {
            const esc = front.replace(/[&<>]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]));
            html = '<pre class="frontmatter"><code class="language-yaml">' + esc + '</code></pre>' + html;
          }

          const el = document.getElementById("content");
          el.innerHTML = DOMPurify.sanitize(html, { ADD_ATTR: ["target"] });

          el.querySelectorAll("pre code").forEach(block => {
            try { hljs.highlightElement(block); } catch (e) {}
          });

          // Anclas en los títulos para que funcionen los enlaces internos (#seccion).
          const used = {};
          el.querySelectorAll("h1,h2,h3,h4,h5,h6").forEach(h => {
            let id = h.textContent.trim().toLowerCase()
              .replace(/[^\\p{L}\\p{N}\\s-]/gu, "").replace(/\\s+/g, "-");
            if (used[id] !== undefined) { used[id] += 1; id += "-" + used[id]; } else { used[id] = 0; }
            h.id = id;
          });
        })();
        </script>
        </body>
        </html>
        """
    }

    private static func resource(_ name: String) -> String {
        let bundle = Bundle(for: BundleToken.self)
        let parts = name.split(separator: ".", maxSplits: 1).map(String.init)
        guard let url = bundle.url(forResource: parts[0], withExtension: parts[1]),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        // Evita que un "</script>" o "</style>" dentro de la librería cierre la etiqueta antes de tiempo.
        return text.replacingOccurrences(of: "</script", with: "<\\/script")
                   .replacingOccurrences(of: "</style", with: "<\\/style")
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private final class BundleToken {}
}
