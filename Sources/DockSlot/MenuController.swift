import AppKit
import ApplicationServices
import DockSlotCore
import ServiceManagement

/// Ícone e menu na barra de menus.
@MainActor
final class MenuController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    override init() {
        super.init()
        statusItem.button?.image = Self.statusImage()
        statusItem.button?.toolTip = "DockSlot"
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !AXIsProcessTrusted() {
            menu.addItem(item("Permitir acesso de Acessibilidade…", #selector(openAccessibilitySettings)))
            menu.addItem(.separator())
        }

        let count = DockPreferences.separatorCount
        let summary = NSMenuItem(title: Self.summary(count), action: nil, keyEquivalent: "")
        summary.isEnabled = false
        menu.addItem(summary)

        let add = NSMenuItem(title: "Adicionar separador", action: nil, keyEquivalent: "")
        add.submenu = addMenu()
        menu.addItem(add)

        let remove = NSMenuItem(title: "Remover separador", action: nil, keyEquivalent: "")
        remove.submenu = removeMenu()
        remove.isEnabled = count > 0
        menu.addItem(remove)

        let removeAll = item("Remover todos", #selector(removeAllSeparators))
        removeAll.isEnabled = count > 0
        menu.addItem(removeAll)

        menu.addItem(.separator())
        let login = item("Abrir ao iniciar sessão", #selector(toggleLoginItem))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Sair do DockSlot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private func addMenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        for section in DockSection.allCases {
            let tiles = DockPreferences.tiles(in: section)
            if section == .others {
                guard !tiles.isEmpty else { continue }
                submenu.addItem(.separator())
            }
            submenu.addItem(positionItem("No início", #selector(addSeparator(_:)), section, 0))
            for (index, tile) in tiles.enumerated() where !TileList.isSeparator(tile) {
                let title = "Depois de \(TileList.label(of: tile))"
                submenu.addItem(positionItem(title, #selector(addSeparator(_:)), section, index + 1))
            }
        }
        return submenu
    }

    private func removeMenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        for section in DockSection.allCases {
            let tiles = DockPreferences.tiles(in: section)
            for (index, tile) in tiles.enumerated() where TileList.isSeparator(tile) {
                let title = TileList.positionDescription(of: index, in: tiles)
                submenu.addItem(positionItem(title, #selector(removeSeparator(_:)), section, index))
            }
        }
        return submenu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func positionItem(_ title: String, _ action: Selector, _ section: DockSection, _ index: Int) -> NSMenuItem {
        let item = item(title, action)
        item.representedObject = TilePosition(section: section, index: index)
        return item
    }

    @objc private func addSeparator(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? TilePosition else { return }
        perform {
            try DockPreferences.update(position.section) {
                TileList.insertingSeparator(into: $0, at: position.index)
            }
        }
    }

    @objc private func removeSeparator(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? TilePosition else { return }
        perform {
            try DockPreferences.update(position.section) {
                TileList.removingSeparator(from: $0, at: position.index)
            }
        }
    }

    @objc private func removeAllSeparators() {
        perform(DockPreferences.removeAllSeparators)
    }

    @objc private func toggleLoginItem() {
        perform {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        }
    }

    @objc private func openAccessibilitySettings() {
        let address = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: address) { NSWorkspace.shared.open(url) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }

    private static func summary(_ count: Int) -> String {
        switch count {
        case 0: "Nenhum separador no Dock"
        case 1: "1 separador no Dock"
        default: "\(count) separadores no Dock"
        }
    }

    private static func statusImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: 2, y: 3, width: 5, height: 12), xRadius: 1.5, yRadius: 1.5).fill()
            NSBezierPath(roundedRect: NSRect(x: 11, y: 3, width: 5, height: 12), xRadius: 1.5, yRadius: 1.5).fill()
            NSRect(x: 8.5, y: 1, width: 1, height: 16).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}

private final class TilePosition: NSObject {
    let section: DockSection
    let index: Int

    init(section: DockSection, index: Int) {
        self.section = section
        self.index = index
    }
}
