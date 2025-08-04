import Foundation
import ApplicationServices
import IOKit.hid
import CoreGraphics
import AppKit
import Combine

class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    @Published var mappings: [ShortcutMapping] = []
    @Published var isAccessibilityEnabled = false
    private var activeShortcuts: [UUID: (eventTap: CFMachPort, sourceHotkey: HotkeyData, targetHotkey: HotkeyData)] = [:]
    private var permissionTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        isAccessibilityEnabled = AXIsProcessTrusted()
        setupAccessibilityObserver()
        
        // Charger les mappings sauvegardés
        loadMappingsFromStorage()
    }
    
    // MARK: - Storage Methods
    private func loadMappingsFromStorage() {
        let loadedMappings = ShortcutStorage.shared.loadMappings()
        self.mappings = loadedMappings
        
        // Log pour déboguer
        print("Chargé \(loadedMappings.count) mappings depuis le stockage")
    }
    
    private func saveMappings() {
        ShortcutStorage.shared.saveMappings(mappings)
        
        // Log pour déboguer
        print("Sauvegardé \(mappings.count) mappings dans le stockage")
    }
    
    // MARK: - Observation Methods
    private func setupAccessibilityObserver() {
        // Utiliser une constante pour le nom de notification pour éviter les erreurs de frappe
        let accessibilityNotificationName = NSNotification.Name("AccessibilityStatusDidChange")
        
        NotificationCenter.default.addObserver(
            forName: accessibilityNotificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let trusted = AXIsProcessTrusted()
            self?.isAccessibilityEnabled = trusted
            
            if trusted {
                self?.reactivateEnabledMappings()
            } else {
                self?.disableAllEventTaps()
            }
        }
    }
    
    // MARK: - Mapping Management
    private func reactivateEnabledMappings() {
        for mapping in mappings where mapping.isEnabled {
            if let source = mapping.sourceHotkey,
               let target = mapping.targetHotkey {
                do {
                    try enableShortcutMapping(id: mapping.id, from: source, to: target)
                } catch {
                    print("Erreur lors de la réactivation du mapping : \(error)")
                    if let index = mappings.firstIndex(where: { $0.id == mapping.id }) {
                        mappings[index].isEnabled = false
                        saveMappings() // Sauvegarder après la modification
                    }
                }
            }
        }
    }
    
    private func disableAllEventTaps() {
        for (id, mapping) in activeShortcuts {
            CGEvent.tapEnable(tap: mapping.eventTap, enable: false)
            if let index = mappings.firstIndex(where: { $0.id == id }) {
                mappings[index].isEnabled = false
            }
        }
        activeShortcuts.removeAll()
        saveMappings() // Sauvegarder après la désactivation de tous les mappings
    }
    
    private func simulateKeyPress(_ hotkeyData: HotkeyData) {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: hotkeyData.keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: hotkeyData.keyCode, keyDown: false) else {
            return
        }
        
        var flags = CGEventFlags()
        let modifiers = hotkeyData.modifierFlags
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if modifiers.contains(.shift) { flags.insert(.maskShift) }
        
        keyDown.flags = flags
        keyUp.flags = flags
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown,
              let nsEvent = NSEvent(cgEvent: event),
              let currentApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = currentApp.bundleIdentifier else {
            return Unmanaged.passRetained(event)
        }
        
        // Vérifier d'abord les mappings spécifiques à l'application
        if let appMapping = self.mappings.first(where: {
            $0.context == bundleId &&
            $0.isEnabled &&
            $0.sourceHotkey?.matches(nsEvent) == true
        }) {
            self.simulateKeyPress(appMapping.targetHotkey!)
            return nil
        }
        
        // Ensuite vérifier les mappings système
        if let systemMapping = self.mappings.first(where: {
            $0.context == "system" &&
            $0.isEnabled &&
            $0.sourceHotkey?.matches(nsEvent) == true
        }) {
            self.simulateKeyPress(systemMapping.targetHotkey!)
            return nil
        }
        
        return Unmanaged.passRetained(event)
    }
    
    // MARK: - Public Methods
    
    // Obtenir des mappings pour un contexte spécifique
    func shortcutsForContext(_ context: String) -> [ShortcutMapping] {
        return mappings.filter { $0.context == context }
    }
    
    // Ajouter un nouveau mapping
    func addMapping(for context: String) {
        let newMapping = ShortcutMapping(context: context)
        mappings.append(newMapping)
        saveMappings()
        objectWillChange.send()
    }
    
    // Mettre à jour un mapping existant (nouvelle méthode)
    func updateMapping(id: UUID, name: String?, source: HotkeyData?, target: HotkeyData?) {
        if let index = mappings.firstIndex(where: { $0.id == id }) {
            if let name = name {
                mappings[index].name = name
            }
            
            if let source = source {
                mappings[index].sourceHotkey = source
            }
            
            if let target = target {
                mappings[index].targetHotkey = target
            }
            
            saveMappings()
            objectWillChange.send()
        }
    }
    
    // Basculer l'état d'activation d'un mapping (nouvelle méthode)
    func toggleMappingEnabled(id: UUID) {
        if let index = mappings.firstIndex(where: { $0.id == id }) {
            let isCurrentlyEnabled = mappings[index].isEnabled
            
            if isCurrentlyEnabled {
                disableShortcutMapping(id: id)
            } else {
                if let source = mappings[index].sourceHotkey,
                   let target = mappings[index].targetHotkey {
                    do {
                        try enableShortcutMapping(id: id, from: source, to: target)
                    } catch {
                        print("Erreur lors de l'activation du mapping : \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Accessibility Permissions
    public func requestAccessibilityPermissions() {
        print("Vérification des permissions d'accessibilité...")
        let trusted = AXIsProcessTrusted()
        isAccessibilityEnabled = trusted
        
        if !trusted {
            print("Demande des permissions d'accessibilité...")
            
            // S'assurer que l'application est au premier plan
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            
            DispatchQueue.main.async {
                // Cette ligne est cruciale pour déclencher la boîte de dialogue
                let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
                
                // Cette ligne va effectivement déclencher la boîte de dialogue
                _ = AXIsProcessTrustedWithOptions(options)
                
                // On force une tentative d'accès aux fonctionnalités d'accessibilité
                let systemWideElement = AXUIElementCreateSystemWide()
                _ = AXUIElementSetMessagingTimeout(systemWideElement, 1.0)
                
                // Configurer le timer pour vérifier les changements de permission
                self.startPermissionMonitoring()
            }
        } else {
            print("Les permissions d'accessibilité sont déjà accordées")
            self.isAccessibilityEnabled = true
            NotificationCenter.default.post(
                name: NSNotification.Name("AccessibilityStatusDidChange"),
                object: nil
            )
        }
    }
    
    private func startPermissionMonitoring() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            let currentTrusted = AXIsProcessTrusted()
            if currentTrusted != self?.isAccessibilityEnabled {
                self?.isAccessibilityEnabled = currentTrusted
                NotificationCenter.default.post(
                    name: NSNotification.Name("AccessibilityStatusDidChange"),
                    object: nil
                )
                
                if currentTrusted {
                    print("Permissions d'accessibilité accordées")
                    timer.invalidate()
                    self?.permissionTimer = nil
                }
            }
        }
    }
    
    public func forceNewPermissionRequest() {
        print("Forçage d'une nouvelle demande de permissions")
        isAccessibilityEnabled = false
        requestAccessibilityPermissions()
    }
    
    // MARK: - Shortcut Activation/Deactivation
    public func enableShortcutMapping(id: UUID, from source: HotkeyData, to target: HotkeyData) throws {
        guard AXIsProcessTrusted() else {
            print("Tentative d'activation du mapping sans les permissions")
            forceNewPermissionRequest()
            throw NSError(domain: "ShortcutManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "L'application nécessite des permissions d'accessibilité"
            ])
        }
        
        // Désactiver l'ancien event tap s'il existe
        if let oldMapping = activeShortcuts[id] {
            CGEvent.tapEnable(tap: oldMapping.eventTap, enable: false)
            activeShortcuts.removeValue(forKey: id)
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, userInfo in
                let manager = Unmanaged<ShortcutManager>.fromOpaque(userInfo!).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            throw NSError(domain: "ShortcutManager", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Impossible de créer l'event tap"
            ])
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        activeShortcuts[id] = (eventTap, source, target)
        
        if let index = mappings.firstIndex(where: { $0.id == id }) {
            mappings[index].isEnabled = true
            saveMappings()
        }
    }
    
    public func disableShortcutMapping(id: UUID) {
        if let mapping = activeShortcuts[id] {
            CGEvent.tapEnable(tap: mapping.eventTap, enable: false)
            activeShortcuts.removeValue(forKey: id)
            
            if let index = mappings.firstIndex(where: { $0.id == id }) {
                mappings[index].isEnabled = false
                saveMappings()
            }
        }
    }
    
    public func deleteMapping(id: UUID) {
        disableShortcutMapping(id: id)
        if let index = mappings.firstIndex(where: { $0.id == id }) {
            mappings.remove(at: index)
            saveMappings()
        }
    }
    
    // MARK: - Import/Export Methods
    func exportShortcuts(to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(mappings)
            try data.write(to: url)
            print("Raccourcis exportés avec succès vers: \(url.path)")
        } catch {
            print("Erreur lors de l'exportation des raccourcis : \(error)")
        }
    }
    
    func importShortcuts(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedMappings = try decoder.decode([ShortcutMapping].self, from: data)
            
            print("Importation de \(importedMappings.count) mappings depuis \(url.path)")
            
            // Désactiver les raccourcis actuels
            for mapping in mappings where mapping.isEnabled {
                disableShortcutMapping(id: mapping.id)
            }
            
            // Extraire les applications uniques
            let importedContexts = Set(importedMappings.map { $0.context })
            
            // Ajouter les nouvelles applications
            for context in importedContexts where context != "system" {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: context),
                   let bundle = Bundle(url: url),
                   let appName = bundle.infoDictionary?["CFBundleName"] as? String {
                    
                    let newApp = CustomApplication(
                        name: appName,
                        bundleIdentifier: context,
                        url: url
                    )
                    
                    Task { @MainActor in
                        var currentApps = StorageManager.shared.loadApplications()
                        if !currentApps.contains(where: { $0.bundleIdentifier == context }) {
                            currentApps.append(newApp)
                            StorageManager.shared.saveApplications(currentApps)
                        }
                    }
                }
            }
            
            // Mettre à jour les mappings
            mappings = importedMappings
            saveMappings() // Important - Sauvegarder les mappings importés
            
            // Réactiver les nouveaux raccourcis
            reactivateEnabledMappings()
        } catch {
            print("Erreur lors de l'importation des raccourcis : \(error)")
        }
    }
}
