import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menu: MenuController?
    private let overlay = OverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu = MenuController()
        overlay.onDockChange = { Diagnostics.write($0) }
        overlay.start()
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
    .filter { !$0.hasPrefix("-psn_") }
if !arguments.isEmpty {
    exit(CommandLineTool.run(arguments))
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
