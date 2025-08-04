import SwiftUI
import AppKit
import Cocoa

@main
struct CustomShortcutsApp: App {
    @StateObject private var shortcutManager = ShortcutManager.shared
    @StateObject private var appsViewModel = ApplicationsViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commandsRemoved()
        .commands {
            // Menu app (About et Quit)
            CommandGroup(replacing: .appInfo) {
                Button(NSLocalizedString("About Custom Shortcuts", comment: "")) {
                    let attributedString = NSMutableAttributedString()
                    
                    let mainText = NSAttributedString(
                        string: "Application made by Léo Durand\n\n",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.labelColor
                        ]
                    )
                    attributedString.append(mainText)
                    
                    let displayUrl = "leodurand.com"
                    let fullUrl = "https://www.leodurand.com/?ref=app"
                    let urlText = NSAttributedString(
                        string: displayUrl,
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.linkColor,
                            .link: URL(string: fullUrl)!
                        ]
                    )
                    attributedString.append(urlText)
                    
                    let options: [NSApplication.AboutPanelOptionKey: Any] = [
                        .credits: attributedString
                    ]
                    
                    NSApplication.shared.orderFrontStandardAboutPanel(options: options)
                }
                
                Divider()
                
                Button(NSLocalizedString("Quit CustomShortcuts", comment: "")) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            
            // Menu File
            CommandGroup(replacing: .newItem) {
                Button(NSLocalizedString("Add an application", comment: "")) {
                    appsViewModel.addApplication()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Divider()
                
                Button(NSLocalizedString("Export shortcuts", comment: "")) {
                    appDelegate.exportShortcuts()
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button(NSLocalizedString("Import shortcuts", comment: "")) {
                    appDelegate.importShortcuts()
                }
                .keyboardShortcut("i", modifiers: .command)
            }
            
            // Menu View
            CommandGroup(after: .sidebar) {
                Button(NSLocalizedString("Show/hide sidebar", comment: "")) {
                    NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 600)
    }
}

// Extension pour ajouter shortcutsImported
extension Notification.Name {
    static let shortcutsImported = Notification.Name("shortcutsImported")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    private var windowController: NSWindowController?
    private var windowFrame: NSRect?
    private let shortcutManager = ShortcutManager.shared
    private let appsViewModel = ApplicationsViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ShortcutManager.shared.requestAccessibilityPermissions()
        observeAccessibilityChanges()
        setupStatusBar()
        NSApp.setActivationPolicy(.regular)
        showApp()
    }

    private func observeAccessibilityChanges() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AccessibilityStatusDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            if AXIsProcessTrusted() {
                print("Permissions d'accessibilité accordées - App Delegate")
            }
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Ouvrir", action: #selector(showApp), keyEquivalent: "o"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quitter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem?.menu = menu
        }
    }
    
    @objc func addApplication() {
        appsViewModel.addApplication()
    }
    
    @objc func exportShortcuts() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Custom-Shortcuts.json"
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                ShortcutManager.shared.exportShortcuts(to: url)
            }
        }
    }
    
    @objc func importShortcuts() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task { @MainActor in
                    ShortcutManager.shared.importShortcuts(from: url)
                    NotificationCenter.default.post(name: .shortcutsImported, object: nil)
                }
            }
        }
    }
    
    private func setupWindow() {
        if windowController != nil { return }
        
        let window = NSWindow(
            contentRect: windowFrame ?? NSRect(x: 0, y: 0, width: 812, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        let contentView = ContentView()
        window.title = "Custom Shortcuts"
        
        window.minSize = NSSize(width: 812, height: 600)
        window.styleMask.insert(.fullSizeContentView)
        
        // Configuration de la toolbar de manière plus native
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        window.titlebarSeparatorStyle = .none
        window.toolbarStyle = .unified
        window.toolbar = toolbar
        
        // Configuration du style de la fenêtre
        window.tabbingMode = .disallowed  // Désactive explicitement les tabs pour cette fenêtre
        window.titlebarAppearsTransparent = false
        
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        window.delegate = self
        
        windowController = NSWindowController(window: window)
        
        if windowFrame == nil {
            window.center()
        }
    }
    
    @objc func showApp() {
        NSApp.setActivationPolicy(.regular)
        
        if windowController == nil {
            setupWindow()
        }
        
        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    @objc func windowWillClose(_ notification: Notification) {
        windowFrame = windowController?.window?.frame
        windowController = nil
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showApp()
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
