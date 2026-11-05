import CoreGraphics
import Foundation

/// Arraste de uma vaga do Dock, iniciado por um clique sobre ela.
///
/// Enquanto a vaga está sendo arrastada, o Dock pode deixar de informá-la. Nesse
/// intervalo a linha acompanha o cursor, como um ícone arrastado.
public struct SpacerDrag: Sendable {
    /// Quanto tempo a linha espera a vaga voltar depois que o botão é solto.
    public static let releaseGrace: TimeInterval = 0.4

    public let spacerCount: Int
    public let grabOffset: CGSize
    public let lineSize: CGSize
    public private(set) var pointer: CGPoint
    public private(set) var releasedAt: Date?

    /// Retorna `nil` quando o clique não caiu sobre nenhuma vaga.
    public init?(pointer: CGPoint, spacers: [CGRect], lines: [CGRect]) {
        guard let index = spacers.firstIndex(where: { $0.contains(pointer) }),
              lines.indices.contains(index) else { return nil }
        let line = lines[index]
        self.pointer = pointer
        spacerCount = spacers.count
        lineSize = line.size
        grabOffset = CGSize(width: pointer.x - line.midX, height: pointer.y - line.midY)
    }

    public mutating func move(to pointer: CGPoint) {
        guard releasedAt == nil else { return }
        self.pointer = pointer
    }

    public mutating func release(at date: Date) {
        if releasedAt == nil { releasedAt = date }
    }

    /// Indica se o arraste terminou, porque a vaga voltou ou o tempo de espera acabou.
    public func isFinished(presentSpacers: Int, now: Date) -> Bool {
        guard let releasedAt else { return false }
        return presentSpacers >= spacerCount || now.timeIntervalSince(releasedAt) >= Self.releaseGrace
    }

    /// Retângulo da linha solta, ou `nil` se o Dock continua informando todas as vagas.
    public func floatingLine(presentSpacers: Int, scale: CGFloat) -> CGRect? {
        guard presentSpacers < spacerCount else { return nil }
        let step = scale > 0 ? scale : 1
        let x = pointer.x - grabOffset.width - lineSize.width / 2
        let y = pointer.y - grabOffset.height - lineSize.height / 2
        return CGRect(
            x: (x * step).rounded() / step,
            y: (y * step).rounded() / step,
            width: lineSize.width,
            height: lineSize.height
        )
    }
}
