import AppKit
import ApplicationServices
import DockSlotCore

struct DockItem {
    let subrole: String
    let title: String
    let frame: CGRect

    var isSpacer: Bool { subrole == "AXSpacerDockItem" }
    var isNativeSeparator: Bool { subrole == "AXSeparatorDockItem" }
}

struct DockSnapshot {
    let listFrame: CGRect
    let items: [DockItem]
}

/// Lê a posição dos itens do Dock pela Accessibility API.
final class DockReader {
    private var application: AXUIElement?
    private var list: AXUIElement?

    func snapshot() -> DockSnapshot? {
        if let snapshot = readList() { return snapshot }
        // O Dock pode ter reiniciado; nesse caso os elementos guardados deixam de valer.
        resolveDock()
        return readList()
    }

    private func resolveDock() {
        application = nil
        list = nil
        guard let dock = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.dock").first else { return }
        let element = AXUIElementCreateApplication(dock.processIdentifier)
        AXUIElementSetMessagingTimeout(element, 0.25)
        application = element
        let children: [AXUIElement] = value(of: element, kAXChildrenAttribute) ?? []
        list = children.first { (value(of: $0, kAXRoleAttribute) as String?) == kAXListRole }
    }

    private func readList() -> DockSnapshot? {
        guard let list, let listFrame = frame(of: list) else { return nil }
        let children: [AXUIElement] = value(of: list, kAXChildrenAttribute) ?? []
        let items = children.compactMap { element -> DockItem? in
            guard let frame = frame(of: element) else { return nil }
            return DockItem(
                subrole: value(of: element, kAXSubroleAttribute) ?? "",
                title: value(of: element, kAXTitleAttribute) ?? "",
                frame: frame
            )
        }
        return DockSnapshot(listFrame: listFrame, items: items)
    }

    private func value<T>(of element: AXUIElement, _ attribute: String) -> T? {
        var result: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &result) == .success else {
            return nil
        }
        return result as? T
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var position: AnyObject?
        var size: AnyObject?
        guard
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position) == .success,
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size) == .success,
            let position, let size
        else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        guard
            AXValueGetValue(position as! AXValue, .cgPoint, &origin),
            AXValueGetValue(size as! AXValue, .cgSize, &extent)
        else { return nil }
        return CGRect(origin: origin, size: extent)
    }
}
