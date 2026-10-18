import Cocoa
import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var documents: [DocumentWindowController] = []
    private var welcomeWindow: NSWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.build()
    }

    // Los ficheros abiertos con doble clic llegan aquí antes de terminar el arranque.
    func applicationDidFinishLaunching(_ notification: Notification) {
        if documents.isEmpty { showWelcome(nil) }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach(open)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showWelcome(nil) }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    // MARK: Abrir ficheros

    func open(_ url: URL) {
        if let existing = documents.first(where: { $0.fileURL.standardizedFileURL == url.standardizedFileURL }) {
            existing.showWindow(nil)
            return
        }
        let controller = DocumentWindowController(fileURL: url)
        controller.onClose = { [weak self] closed in
            self?.documents.removeAll { $0 === closed }
        }
        if let window = controller.window {
            if let last = documents.last?.window {
                window.setFrameTopLeftPoint(window.cascadeTopLeft(from: NSPoint(x: last.frame.minX, y: last.frame.maxY)))
            } else {
                window.center()
            }
        }
        documents.append(controller)
        controller.showWindow(nil)
        welcomeWindow?.close()
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = MarkdownPage.fileExtensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK { panel.urls.forEach(open) }
    }

    @objc func showWelcome(_ sender: Any?) {
        if welcomeWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: WelcomeView(
                openFile: { [weak self] in self?.openDocument(nil) },
                openURL: { [weak self] url in self?.open(url) })))
            window.title = "Vistazo MD"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            welcomeWindow = window
        }
        welcomeWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}

/// Menú principal construido por código (no hay storyboard).
enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()

        let appMenu = submenu(in: main, title: "Vistazo MD")
        appMenu.addItem(withTitle: "Acerca de Vistazo MD", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Ocultar Vistazo MD", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Ocultar otros", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            .keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Mostrar todo", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Salir de Vistazo MD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let file = submenu(in: main, title: "Archivo")
        file.addItem(withTitle: "Abrir…", action: #selector(AppDelegate.openDocument(_:)), keyEquivalent: "o")
        file.addItem(withTitle: "Bienvenida", action: #selector(AppDelegate.showWelcome(_:)), keyEquivalent: "")
        file.addItem(.separator())
        file.addItem(withTitle: "Cerrar", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let edit = submenu(in: main, title: "Edición")
        edit.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Seleccionar todo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let view = submenu(in: main, title: "Visualización")
        view.addItem(withTitle: "Recargar", action: #selector(DocumentWindowController.reloadDocument(_:)), keyEquivalent: "r")
        view.addItem(.separator())
        view.addItem(withTitle: "Tamaño real", action: #selector(DocumentWindowController.actualSize(_:)), keyEquivalent: "0")
        view.addItem(withTitle: "Ampliar", action: #selector(DocumentWindowController.zoomIn(_:)), keyEquivalent: "+")
        view.addItem(withTitle: "Reducir", action: #selector(DocumentWindowController.zoomOut(_:)), keyEquivalent: "-")

        let window = submenu(in: main, title: "Ventana")
        window.addItem(withTitle: "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        window.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        window.addItem(.separator())
        window.addItem(withTitle: "Traer todo al frente", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        NSApp.windowsMenu = window

        return main
    }

    private static func submenu(in menu: NSMenu, title: String) -> NSMenu {
        let item = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        item.submenu = submenu
        return submenu
    }
}
