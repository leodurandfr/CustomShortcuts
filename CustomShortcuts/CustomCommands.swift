// CustomCommands.swift
import SwiftUI
import AppKit
import Cocoa

struct CustomCommands: Commands {
    @ObservedObject var appsViewModel: ApplicationsViewModel
    let shortcutManager: ShortcutManager
    
    init(appsViewModel: ApplicationsViewModel, shortcutManager: ShortcutManager) {
        self.appsViewModel = appsViewModel
        self.shortcutManager = shortcutManager
        
        removeSystemMenus()
    }
    
    func removeSystemMenus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let mainMenu = NSApplication.shared.mainMenu {
                let windowTitle = NSLocalizedString("Window", comment: "")
                let helpTitle = NSLocalizedString("Help", comment: "")
                
                for item in mainMenu.items.reversed() {
                    if item.title == windowTitle || item.title == helpTitle {
                        mainMenu.removeItem(item)
                    }
                }
                NSWindow.allowsAutomaticWindowTabbing = false
            }
        }
    }
    
    
    var body: some Commands {
        // Menu app (About et Quit)
        CommandGroup(replacing: .appInfo) {
                Button(NSLocalizedString("About Custom Shortcuts", comment: "")) {
                    let attributedString = NSMutableAttributedString()
                    
                    // Texte normal
                    let mainText = NSAttributedString(
                        string: "Application made by Léo Durand\n\n",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.labelColor
                        ]
                    )
                    attributedString.append(mainText)
                    
                    // URL cliquable avec texte personnalisé
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
        
        // Menu File avec commandes personnalisées
         CommandGroup(replacing: .newItem) {
             Button(NSLocalizedString("Add an application", comment: "")) {
                 appsViewModel.addApplication()
             }
             .keyboardShortcut("n", modifiers: .command)
             
             Divider()
             
             Button(NSLocalizedString("Export shortcuts", comment: "")) {
                 exportShortcuts()
             }
             .keyboardShortcut("e", modifiers: .command)
             
             Button(NSLocalizedString("Import shortcuts", comment: "")) {
                 importShortcuts()
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
        
        // Supprimer les menus Window et Help
          CommandGroup(replacing: .windowSize) { }
          CommandGroup(replacing: .windowList) { }
          CommandGroup(replacing: .windowArrangement) { }
          CommandGroup(replacing: .help) { }
          
    }
    
    private func importShortcuts() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task { @MainActor in
                    shortcutManager.importShortcuts(from: url)
                    NotificationCenter.default.post(
                        name: .shortcutsImported,
                        object: nil
                    )
                }
            }
        }
    }
    
    private func exportShortcuts() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Custom-Shortcuts.json"
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                shortcutManager.exportShortcuts(to: url)
            }
        }
    }
}
