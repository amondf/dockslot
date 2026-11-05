import CoreGraphics
import Foundation
import Testing
@testable import DockSlotCore

@Suite struct SpacerDragTests {
    private let spacer = CGRect(x: 100, y: 5, width: 34, height: 84)
    private let line = CGRect(x: 117, y: 16, width: 1, height: 62)

    @Test func ignoraCliqueForaDaVaga() {
        #expect(SpacerDrag(pointer: CGPoint(x: 10, y: 10), spacers: [spacer], lines: [line]) == nil)
    }

    @Test func linhaFicaNoLugarAoPegarAVaga() throws {
        let drag = try #require(SpacerDrag(pointer: CGPoint(x: 110, y: 30), spacers: [spacer], lines: [line]))
        #expect(drag.floatingLine(presentSpacers: 0, scale: 1) == line)
    }

    @Test func linhaAcompanhaOCursor() throws {
        var drag = try #require(SpacerDrag(pointer: CGPoint(x: 110, y: 30), spacers: [spacer], lines: [line]))
        drag.move(to: CGPoint(x: 310, y: 130))
        #expect(drag.floatingLine(presentSpacers: 0, scale: 1) == line.offsetBy(dx: 200, dy: 100))
    }

    @Test func naoDuplicaLinhaSeOVagaContinuaNoDock() throws {
        let drag = try #require(SpacerDrag(pointer: CGPoint(x: 110, y: 30), spacers: [spacer], lines: [line]))
        #expect(drag.floatingLine(presentSpacers: 1, scale: 1) == nil)
    }

    @Test func congelaPosicaoDepoisDeSoltar() throws {
        var drag = try #require(SpacerDrag(pointer: CGPoint(x: 110, y: 30), spacers: [spacer], lines: [line]))
        drag.release(at: Date(timeIntervalSince1970: 0))
        drag.move(to: CGPoint(x: 900, y: 900))
        #expect(drag.pointer == CGPoint(x: 110, y: 30))
    }

    @Test func terminaQuandoAVagaVoltaOuOTempoAcaba() throws {
        var drag = try #require(SpacerDrag(pointer: CGPoint(x: 110, y: 30), spacers: [spacer], lines: [line]))
        let start = Date(timeIntervalSince1970: 0)
        #expect(!drag.isFinished(presentSpacers: 1, now: start))
        drag.release(at: start)
        #expect(drag.isFinished(presentSpacers: 1, now: start))
        #expect(!drag.isFinished(presentSpacers: 0, now: start.addingTimeInterval(0.1)))
        #expect(drag.isFinished(presentSpacers: 0, now: start.addingTimeInterval(0.5)))
    }
}
