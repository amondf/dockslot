import Foundation
import Testing
@testable import DockSlotCore

private func app(_ name: String) -> Tile {
    ["tile-type": "file-tile", "tile-data": ["file-label": name] as Tile]
}

@Suite struct TileListTests {
    @Test func insereNaPosicaoPedida() {
        let result = TileList.insertingSeparator(into: [app("A"), app("B")], at: 1)
        #expect(result.count == 3)
        #expect(TileList.isSeparator(result[1]))
        #expect(TileList.label(of: result[2]) == "B")
    }

    @Test func limitaIndiceForaDaLista() {
        let tiles = [app("A")]
        #expect(TileList.isSeparator(TileList.insertingSeparator(into: tiles, at: 99)[1]))
        #expect(TileList.isSeparator(TileList.insertingSeparator(into: tiles, at: -5)[0]))
    }

    @Test func naoRemoveItemQueNaoESeparador() {
        let tiles = [app("A"), app("B")]
        #expect(TileList.removingSeparator(from: tiles, at: 0).count == 2)
        #expect(TileList.removingSeparator(from: tiles, at: 7).count == 2)
    }

    @Test func removeTodosEPreservaApps() {
        let tiles = TileList.insertingSeparator(
            into: TileList.insertingSeparator(into: [app("A"), app("B")], at: 2), at: 1)
        #expect(TileList.separatorCount(in: tiles) == 2)
        let clean = TileList.removingAllSeparators(from: tiles)
        #expect(clean.map(TileList.label(of:)) == ["A", "B"])
    }

    @Test func reconheceOsTresTiposDeEspacador() {
        for type in ["small-spacer-tile", "spacer-tile", "flex-spacer-tile"] {
            #expect(TileList.isSeparator(["tile-type": type]))
        }
        #expect(!TileList.isSeparator(app("A")))
    }

    @Test func descrevePosicaoPeloVizinho() {
        let tiles = [TileList.makeSeparator(), app("A"), TileList.makeSeparator(), TileList.makeSeparator()]
        #expect(TileList.positionDescription(of: 0, in: tiles) == "No início")
        #expect(TileList.positionDescription(of: 3, in: tiles) == "Depois de A")
    }

    @Test func preservaDadosBinariosDosItens() {
        let bookmark = Data([0x01, 0x02, 0x03])
        let tile: Tile = ["tile-type": "file-tile", "tile-data": ["book": bookmark] as Tile]
        let result = TileList.insertingSeparator(into: [tile], at: 0)
        let data = result[1]["tile-data"] as? Tile
        #expect(data?["book"] as? Data == bookmark)
    }
}
