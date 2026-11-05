import DockSlotCore
import Foundation

/// Comandos para usar sem a barra de menus, como `DockSlot list`.
enum CommandLineTool {
    static func run(_ arguments: [String]) -> Int32 {
        do {
            switch (arguments.first, arguments.dropFirst().first.flatMap(Int.init)) {
            case ("list", _):
                list()
            case ("add", let index?):
                try DockPreferences.update(.apps) { TileList.insertingSeparator(into: $0, at: index) }
            case ("remove", let index?):
                try DockPreferences.update(.apps) { TileList.removingSeparator(from: $0, at: index) }
            case ("clear", _):
                try DockPreferences.removeAllSeparators()
            default:
                print("Uso: DockSlot list | add <posição> | remove <posição> | clear")
                return 64
            }
            return 0
        } catch {
            print("Erro: \(error.localizedDescription)")
            return 1
        }
    }

    private static func list() {
        for (index, tile) in DockPreferences.tiles(in: .apps).enumerated() {
            print(index, TileList.isSeparator(tile) ? "— separador —" : TileList.label(of: tile))
        }
    }
}
