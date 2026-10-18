import Cocoa

// Ciclo de vida en AppKit: así controlamos qué ventanas se abren al lanzar la app
// (una por fichero al hacer doble clic, o la bienvenida si se abre sin ficheros).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
