import Foundation
import SwiftUI
import ServiceManagement
import AppKit

@MainActor
final class ApplicationsViewModel: ObservableObject {
    @Published private(set) var applications: [CustomApplication] = []
    @Published var selectedContext: String = "system" {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private var iconCache: [String: NSImage] = [:]
    
    init() {
        loadApplications()
        setupNotifications()  // Ajout de l'initialisation des notifications
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShortcutsImported),
            name: .shortcutsImported,
            object: nil
        )
    }
    
    @objc private func handleShortcutsImported() {
        Task { @MainActor in
            // Récupérer les contextes des raccourcis importés
            let importedContexts = Set(ShortcutManager.shared.mappings.map { $0.context })
            
            for context in importedContexts where context != "system" {
                if !applications.contains(where: { $0.bundleIdentifier == context }) {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: context),
                       let bundle = Bundle(url: url),
                       let appName = bundle.infoDictionary?["CFBundleName"] as? String {
                        
                        let newApp = CustomApplication(
                            name: appName,
                            bundleIdentifier: context,
                            url: url
                        )
                        
                        applications.append(newApp)
                        loadIcon(for: newApp)
                    }
                }
            }
            
            saveApplications()
        }
    }
    
    private func loadApplications() {
        applications = StorageManager.shared.loadApplications()
        applications.forEach { loadIcon(for: $0) }
    }
    
    func addApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        panel.begin { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = panel.url,
                  let bundle = Bundle(url: url),
                  let bundleIdentifier = bundle.bundleIdentifier,
                  let appName = bundle.infoDictionary?["CFBundleName"] as? String else {
                return
            }
            
            guard !self.applications.contains(where: { $0.bundleIdentifier == bundleIdentifier }) else {
                return
            }
            
            let app = CustomApplication(
                name: appName,
                bundleIdentifier: bundleIdentifier,
                url: url
            )
            
            Task { @MainActor in
                self.applications.append(app)
                self.loadIcon(for: app)
                self.saveApplications()
                // Mettre à jour selectedContext pour basculer sur la nouvelle application
                self.selectedContext = bundleIdentifier
            }
        }
    }
    
    func removeApplication(_ app: CustomApplication) {
        Task { @MainActor in
            guard let indexToRemove = applications.firstIndex(where: { $0.id == app.id }) else {
                return
            }
            
            // Supprimer les raccourcis
            let appShortcuts = ShortcutManager.shared.shortcutsForContext(app.bundleIdentifier)
            for shortcut in appShortcuts {
                ShortcutManager.shared.deleteMapping(id: shortcut.id)
            }
            
            // Mettre à jour la sélection si nécessaire
            if selectedContext == app.bundleIdentifier {
                DispatchQueue.main.async {
                    self.selectedContext = indexToRemove > 0 ?
                        self.applications[indexToRemove - 1].bundleIdentifier :
                        "system"
                }
            }
            
            // Supprimer l'application
            applications.remove(at: indexToRemove)
            iconCache.removeValue(forKey: app.bundleIdentifier)
            saveApplications()
        }
    }
    
    
    private func saveApplications() {
        StorageManager.shared.saveApplications(applications)
    }
    func getIcon(for app: CustomApplication) -> NSImage? {
           if let cachedIcon = iconCache[app.bundleIdentifier] {
               return cachedIcon
           }
           // Au lieu d'appeler loadIcon directement, on le fait de manière asynchrone
           DispatchQueue.main.async {
               self.loadIcon(for: app)
           }
           return nil
       }
       
       private func loadIcon(for app: CustomApplication) {
           let icon = NSWorkspace.shared.icon(forFile: app.url.path)
           iconCache[app.bundleIdentifier] = icon
           DispatchQueue.main.async {
               self.objectWillChange.send()
           }
       }
}
