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
}
