import AppKit
import DockSlotCore

/// Janela de uma linha: transparente para cliques e presente em todos os Spaces.
private final class LineWindow: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Mantém uma linha sobre cada vaga do Dock.
///
/// Fica em ritmo lento enquanto nada muda e acelera quando o Dock se mexe ou o mouse
/// se aproxima dele.
@MainActor
final class OverlayController {
    private static let idleInterval: TimeInterval = 0.25
    private static let activeInterval: TimeInterval = 1.0 / 60
    private static let activeDuration: TimeInterval = 0.6
    private static let mouseMargin: CGFloat = 120

    private let reader = DockReader()
    private var windows: [LineWindow] = []
    private var timer: Timer?
    private var interval: TimeInterval = 0
    private var activeUntil = Date.distantPast
    private var lastFrames: [CGRect] = []
    private var dockRegion = CGRect.null
    private var mouseMonitor: Any?
    private var placed: [PlacedLine] = []
    private var drag: SpacerDrag?

    var onDockChange: ((DockSnapshot) -> Void)?

    func start() {
        schedule(Self.idleInterval)
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        ) { [weak self] event in
            let isPress = event.type == .leftMouseDown
            MainActor.assumeIsolated { self?.mouseEvent(isPress: isPress) }
        }
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.wakeUp() }
            }
        }
    }

    func wakeUp() {
        activeUntil = Date().addingTimeInterval(Self.activeDuration)
        schedule(Self.activeInterval)
    }

    private func mouseEvent(isPress: Bool) {
        let pointer = NSEvent.mouseLocation
        if isPress {
            drag = SpacerDrag(pointer: pointer, spacers: placed.map(\.spacer), lines: placed.map(\.line))
            if drag != nil {
                Diagnostics.startDragTrace()
                wakeUp()
            }
        }
        guard dockRegion.contains(pointer), Date() >= activeUntil else { return }
        wakeUp()
    }

    private func schedule(_ newInterval: TimeInterval) {
        guard newInterval != interval else { return }
        interval = newInterval
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        guard AXIsProcessTrusted() else {
            drag = nil
            placed = []
            show(lines: [], style: .current)
            return
        }

        let style = LineStyle.current
        let snapshot = reader.snapshot()
        if let snapshot {
            observe(snapshot)
            placed = placedLines(for: snapshot, style: style)
        } else if drag == nil {
            placed = []
        }

        var lines = placed.map(\.line)
        if let floating = updateDrag(presentSpacers: placed.count) { lines.append(floating) }
        if drag != nil {
            Diagnostics.traceDrag(snapshot, floating: lines.count > placed.count)
            activeUntil = Date().addingTimeInterval(Self.activeDuration)
        }

        show(lines: lines, style: style)
        schedule(Date() < activeUntil ? Self.activeInterval : Self.idleInterval)
    }

    private func observe(_ snapshot: DockSnapshot) {
        dockRegion = SeparatorGeometry
            .flipped(snapshot.listFrame, primaryScreenHeight: primaryHeight)
            .insetBy(dx: -Self.mouseMargin, dy: -Self.mouseMargin)

        let frames = snapshot.items.map(\.frame)
        guard frames != lastFrames else { return }
        if frames.count != lastFrames.count { onDockChange?(snapshot) }
        lastFrames = frames
        activeUntil = Date().addingTimeInterval(Self.activeDuration)
    }

    /// Atualiza o arraste e retorna a linha que acompanha o cursor, se houver.
    private func updateDrag(presentSpacers: Int) -> CGRect? {
        guard var current = drag else { return nil }
        let now = Date()
        if NSEvent.pressedMouseButtons & 1 == 0 {
            current.release(at: now)
        } else {
            current.move(to: NSEvent.mouseLocation)
        }
        if current.isFinished(presentSpacers: presentSpacers, now: now) {
            drag = nil
            return nil
        }
        drag = current
        return current.floatingLine(presentSpacers: presentSpacers, scale: scale(at: current.pointer))
    }

    private var primaryHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    private func scale(at point: CGPoint) -> CGFloat {
        NSScreen.screens.first { $0.frame.contains(point) }?.backingScaleFactor ?? 1
    }

    private func placedLines(for snapshot: DockSnapshot, style: LineStyle) -> [PlacedLine] {
        let axis = DockAxis(listFrame: snapshot.listFrame)
        let height = primaryHeight
        let reference = snapshot.items.first(where: \.isNativeSeparator)
            .map { SeparatorGeometry.flipped($0.frame, primaryScreenHeight: height) }
        return snapshot.items.filter(\.isSpacer).compactMap { item in
            let spacer = SeparatorGeometry.flipped(item.frame, primaryScreenHeight: height)
            let center = CGPoint(x: spacer.midX, y: spacer.midY)
            guard NSScreen.screens.contains(where: { $0.frame.contains(center) }) else { return nil }
            let line = SeparatorGeometry.lineRect(
                spacer: spacer,
                reference: reference,
                axis: axis,
                thickness: style.thickness,
                lengthRatio: style.lengthRatio,
                scale: scale(at: center)
            )
            return PlacedLine(spacer: spacer, line: line)
        }
    }

    private func show(lines: [CGRect], style: LineStyle) {
        while windows.count < lines.count { windows.append(LineWindow()) }
        for (index, window) in windows.enumerated() {
            guard index < lines.count else {
                window.orderOut(nil)
                continue
            }
            if window.backgroundColor != style.color { window.backgroundColor = style.color }
            if window.frame != lines[index] { window.setFrame(lines[index], display: false) }
            if !window.isVisible { window.orderFrontRegardless() }
        }
    }
}

/// Uma vaga do Dock e a linha desenhada sobre ela, em coordenadas do AppKit.
private struct PlacedLine {
    let spacer: CGRect
    let line: CGRect
}
