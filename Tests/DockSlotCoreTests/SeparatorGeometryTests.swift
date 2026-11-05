import CoreGraphics
import Testing
@testable import DockSlotCore

@Suite struct SeparatorGeometryTests {
    @Test func linhaVerticalCentradaNaVaga() {
        let rect = SeparatorGeometry.lineRect(
            spacer: CGRect(x: 100, y: 1000, width: 30, height: 70),
            reference: CGRect(x: 500, y: 1004, width: 20, height: 62),
            axis: .horizontal, thickness: 1, lengthRatio: 1, scale: 1)
        #expect(rect.width == 1)
        #expect(rect.height == 62)
        #expect(abs(rect.midX - 115) <= 0.5)
        #expect(rect.midY == 1035)
    }

    @Test func linhaHorizontalNoDockLateral() {
        let rect = SeparatorGeometry.lineRect(
            spacer: CGRect(x: 0, y: 300, width: 70, height: 30),
            reference: nil,
            axis: .vertical, thickness: 1, lengthRatio: 0.5, scale: 2)
        #expect(rect.height == 1)
        #expect(rect.width == 35)
        #expect(rect.midX == 35)
    }

    @Test func alinhaAoPixelDaTela() {
        let rect = SeparatorGeometry.lineRect(
            spacer: CGRect(x: 10.3, y: 0, width: 10, height: 50),
            reference: nil,
            axis: .horizontal, thickness: 1, lengthRatio: 1, scale: 2)
        #expect((rect.minX * 2).truncatingRemainder(dividingBy: 1) == 0)
    }

    @Test func inverteCoordenadas() {
        let rect = SeparatorGeometry.flipped(
            CGRect(x: 5, y: 1000, width: 1, height: 60), primaryScreenHeight: 1080)
        #expect(rect == CGRect(x: 5, y: 20, width: 1, height: 60))
    }

    @Test func detectaEixoPeloFormatoDaLista() {
        #expect(DockAxis(listFrame: CGRect(x: 0, y: 0, width: 800, height: 80)) == .horizontal)
        #expect(DockAxis(listFrame: CGRect(x: 0, y: 0, width: 80, height: 800)) == .vertical)
    }
}
