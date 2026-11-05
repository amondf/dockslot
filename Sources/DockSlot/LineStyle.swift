import AppKit

/// Aparência da linha, medida a partir do separador nativo.
///
/// O Dock escurece o fundo com um blend subtrativo, que janelas comuns não conseguem
/// reproduzir. Preto com 39% de opacidade é a aproximação mais próxima em fundos médios.
/// Os valores podem ser ajustados com `defaults write io.github.amondf.dockslot <chave>`.
struct LineStyle {
    let thickness: CGFloat
    let lengthRatio: CGFloat
    let color: NSColor

    @MainActor static var current: LineStyle {
        let defaults = UserDefaults.standard
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let opacity = isDark
            ? defaults.number(for: "lineOpacityDark", fallback: 0.25)
            : defaults.number(for: "lineOpacityLight", fallback: 0.39)
        return LineStyle(
            thickness: defaults.number(for: "lineThickness", fallback: 1),
            lengthRatio: defaults.number(for: "lineLengthRatio", fallback: 1),
            color: (isDark ? NSColor.white : NSColor.black).withAlphaComponent(opacity)
        )
    }
}

private extension UserDefaults {
    func number(for key: String, fallback: CGFloat) -> CGFloat {
        object(forKey: key) == nil ? fallback : CGFloat(double(forKey: key))
    }
}
