import CoreGraphics

public enum DockAxis: Sendable {
    /// Dock embaixo: os itens ficam lado a lado e a linha é vertical.
    case horizontal
    /// Dock à esquerda ou à direita: os itens ficam empilhados e a linha é horizontal.
    case vertical

    public init(listFrame: CGRect) {
        self = listFrame.width >= listFrame.height ? .horizontal : .vertical
    }
}

public enum SeparatorGeometry {
    /// Calcula o retângulo da linha, nas coordenadas de entrada.
    ///
    /// - Parameters:
    ///   - spacer: retângulo da vaga no Dock.
    ///   - reference: retângulo do separador nativo, que define o comprimento e a
    ///     altura da linha. Sem ele, usa a própria vaga.
    ///   - lengthRatio: fração do comprimento de `reference` ocupada pela linha.
    ///   - scale: fator de escala da tela, usado para alinhar a linha ao pixel.
    public static func lineRect(
        spacer: CGRect,
        reference: CGRect?,
        axis: DockAxis,
        thickness: CGFloat,
        lengthRatio: CGFloat,
        scale: CGFloat
    ) -> CGRect {
        let base = reference ?? spacer
        switch axis {
        case .horizontal:
            let length = base.height * lengthRatio
            return CGRect(
                x: snap(spacer.midX - thickness / 2, scale: scale),
                y: snap(base.midY - length / 2, scale: scale),
                width: thickness,
                height: snap(length, scale: scale)
            )
        case .vertical:
            let length = base.width * lengthRatio
            return CGRect(
                x: snap(base.midX - length / 2, scale: scale),
                y: snap(spacer.midY - thickness / 2, scale: scale),
                width: snap(length, scale: scale),
                height: thickness
            )
        }
    }

    /// Converte da origem superior esquerda (Accessibility) para a inferior esquerda (AppKit).
    public static func flipped(_ rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    private static func snap(_ value: CGFloat, scale: CGFloat) -> CGFloat {
        guard scale > 0 else { return value }
        return (value * scale).rounded() / scale
    }
}
