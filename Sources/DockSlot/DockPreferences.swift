import AppKit
import DockSlotCore

/// Lê e grava a lista de itens fixos do Dock.
enum DockPreferences {
    private static var domain: CFString { "com.apple.dock" as CFString }

    static func tiles(in section: DockSection) -> [Tile] {
        CFPreferencesAppSynchronize(domain)
        let value = CFPreferencesCopyAppValue(section.rawValue as CFString, domain)
        return (value as? [Tile]) ?? []
    }

    /// Grava a nova lista, guarda um backup da anterior e reinicia o Dock.
    static func update(_ section: DockSection, transform: ([Tile]) -> [Tile]) throws {
        let current = tiles(in: section)
        let updated = transform(current)
        guard updated.count != current.count else { return }
        try backup(current, section: section)
        CFPreferencesSetAppValue(section.rawValue as CFString, updated as CFArray, domain)
        guard CFPreferencesAppSynchronize(domain) else { throw DockSlotError.preferencesNotSaved }
        try restartDock()
    }

    static func removeAllSeparators() throws {
        for section in DockSection.allCases {
            try update(section, transform: TileList.removingAllSeparators(from:))
        }
    }

    static var separatorCount: Int {
        DockSection.allCases.reduce(0) { $0 + TileList.separatorCount(in: tiles(in: $1)) }
    }

    private static func backup(_ tiles: [Tile], section: DockSection) throws {
        let folder = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DockSlot/Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let stamp = Int(Date().timeIntervalSince1970)
        let file = folder.appendingPathComponent("\(section.rawValue)-\(stamp).plist")
        let data = try PropertyListSerialization.data(fromPropertyList: tiles, format: .binary, options: 0)
        try data.write(to: file)
    }

    private static func restartDock() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try process.run()
        process.waitUntilExit()
    }
}

enum DockSlotError: LocalizedError {
    case preferencesNotSaved

    var errorDescription: String? {
        switch self {
        case .preferencesNotSaved: "Não foi possível salvar as preferências do Dock."
        }
    }
}
