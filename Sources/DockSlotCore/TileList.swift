import Foundation

/// Uma entrada de `persistent-apps` ou `persistent-others` nas preferências do Dock.
public typealias Tile = [String: Any]

/// Seções do Dock que aceitam itens fixos.
public enum DockSection: String, CaseIterable, Sendable {
    case apps = "persistent-apps"
    case others = "persistent-others"
}

/// Operações puras sobre a lista de itens do Dock.
public enum TileList {
    private static let spacerTypes: Set<String> = ["small-spacer-tile", "spacer-tile", "flex-spacer-tile"]

    public static func makeSeparator() -> Tile {
        ["tile-type": "small-spacer-tile", "tile-data": Tile()]
    }

    public static func isSeparator(_ tile: Tile) -> Bool {
        guard let type = tile["tile-type"] as? String else { return false }
        return spacerTypes.contains(type)
    }

    public static func label(of tile: Tile) -> String {
        let data = tile["tile-data"] as? Tile
        return (data?["file-label"] as? String) ?? (data?["label"] as? String) ?? "Item sem nome"
    }

    /// Insere um separador em `index`, limitando o valor ao tamanho da lista.
    public static func insertingSeparator(into tiles: [Tile], at index: Int) -> [Tile] {
        var result = tiles
        result.insert(makeSeparator(), at: min(max(index, 0), tiles.count))
        return result
    }

    /// Remove o item em `index` somente se ele for um separador.
    public static func removingSeparator(from tiles: [Tile], at index: Int) -> [Tile] {
        guard tiles.indices.contains(index), isSeparator(tiles[index]) else { return tiles }
        var result = tiles
        result.remove(at: index)
        return result
    }

    public static func removingAllSeparators(from tiles: [Tile]) -> [Tile] {
        tiles.filter { !isSeparator($0) }
    }

    public static func separatorCount(in tiles: [Tile]) -> Int {
        tiles.filter(isSeparator).count
    }

    /// Descreve a posição do separador em `index` pelo item vizinho.
    public static func positionDescription(of index: Int, in tiles: [Tile]) -> String {
        let previous = tiles[..<index].last { !isSeparator($0) }
        if let previous { return "Depois de \(label(of: previous))" }
        return "No início"
    }
}
