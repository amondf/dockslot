import AppKit
import ApplicationServices

/// Grava o que o app enxerga do Dock em ~/Library/Logs/DockSlot/diagnostico.txt.
enum Diagnostics {
    static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DockSlot/diagnostico.txt")
    }

    @MainActor
    static func write(_ snapshot: DockSnapshot) {
        var lines = ["acessibilidade: \(AXIsProcessTrusted())", "lista: \(snapshot.listFrame)"]
        for screen in NSScreen.screens {
            lines.append("tela: \(screen.frame) escala \(screen.backingScaleFactor)")
        }
        for item in snapshot.items {
            lines.append("\(item.subrole) '\(item.title)' \(item.frame)")
        }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? lines.joined(separator: "\n").appending("\n").write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static var dragTraceURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("arraste.txt")
    }

    @MainActor private static var lastDragState = ""
    @MainActor private static var dragTraceStart = Date()

    /// Inicia um novo registro do que o Dock informa durante um arraste.
    @MainActor
    static func startDragTrace() {
        lastDragState = ""
        dragTraceStart = Date()
        try? FileManager.default.createDirectory(
            at: dragTraceURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? "".write(to: dragTraceURL, atomically: true, encoding: .utf8)
    }

    /// Acrescenta uma linha ao registro quando o estado informado pelo Dock muda.
    @MainActor
    static func traceDrag(_ snapshot: DockSnapshot?, floating: Bool) {
        let items = snapshot.map { snapshot in
            let spacers = snapshot.items.filter(\.isSpacer).map { "\($0.frame)" }
            return "itens=\(snapshot.items.count) vagas=\(spacers)"
        } ?? "sem leitura"
        let state = "\(items) linha_solta=\(floating)"
        guard state != lastDragState, let handle = try? FileHandle(forWritingTo: dragTraceURL) else { return }
        lastDragState = state
        let elapsed = String(format: "%.3f", Date().timeIntervalSince(dragTraceStart))
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: Data("\(elapsed)s \(state)\n".utf8))
        try? handle.close()
    }
}
