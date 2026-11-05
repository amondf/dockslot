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

    var onDockChange: ((DockSnapshot) -> Void)?

    func start() {
        schedule(Self.idleInterval)
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.mouseMoved() }
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

    private func mouseMoved() {
        guard dockRegion.contains(NSEvent.mouseLocation), Date() >= activeUntil else { return }
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
        guard AXIsProcessTrusted(), let snapshot = reader.snapshot() else {
            show(lines: [], style: .current)
            return
        }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        dockRegion = SeparatorGeometry
            .flipped(snapshot.listFrame, primaryScreenHeight: primaryHeight)
            .insetBy(dx: -Self.mouseMargin, dy: -Self.mouseMargin)

        let frames = snapshot.items.map(\.frame)
        if frames != lastFrames {
            if frames.count != lastFrames.count { onDockChange?(snapshot) }
            lastFrames = frames
            activeUntil = Date().addingTimeInterval(Self.activeDuration)
        }

        let style = LineStyle.current
        show(lines: lines(for: snapshot, style: style, primaryHeight: primaryHeight), style: style)
        schedule(Date() < activeUntil ? Self.activeInterval : Self.idleInterval)
    }

    private func lines(for snapshot: DockSnapshot, style: LineStyle, primaryHeight: CGFloat) -> [CGRect] {
        let axis = DockAxis(listFrame: snapshot.listFrame)
        let reference = snapshot.items.first(where: \.isNativeSeparator)?.frame
        return snapshot.items.filter(\.isSpacer).compactMap { item in
            let flipped = SeparatorGeometry.flipped(item.frame, primaryScreenHeight: primaryHeight)
            let center = CGPoint(x: flipped.midX, y: flipped.midY)
            guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) else {
                return nil
            }
            return SeparatorGeometry.lineRect(
                spacer: flipped,
                reference: reference.map { SeparatorGeometry.flipped($0, primaryScreenHeight: primaryHeight) },
                axis: axis,
                thickness: style.thickness,
                lengthRatio: style.lengthRatio,
                scale: screen.backingScaleFactor
            )
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
