import Foundation

/// Avisa cuando un fichero cambia en disco. Soporta el guardado "atómico" que usan
/// muchos editores (escriben un fichero nuevo y lo renombran encima del original).
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        start(retries: 0)
    }

    deinit { stop() }

    func stop() {
        pending?.cancel()
        source?.cancel()
        source = nil
    }

    private func start(retries: Int) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
            // El fichero puede no existir un instante durante un guardado atómico.
            if retries < 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in self?.start(retries: retries + 1) }
            }
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        source.setEventHandler { [weak self, unowned source] in
            guard let self else { return }
            if !source.data.intersection([.delete, .rename]).isEmpty {
                // El fichero que vigilábamos ya no está en esa ruta: volvemos a abrir la ruta.
                self.source?.cancel()
                self.source = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.start(retries: 0) }
            }
            self.scheduleChange()
        }
        source.setCancelHandler { close(descriptor) }
        self.source = source
        source.resume()
    }

    private func scheduleChange() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
}
