//ShortcutActivationService.swift
import Foundation
import Combine

class ShortcutActivationService: ObservableObject {
    static let shared = ShortcutActivationService()
    
    @Published var lastError: String?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        NotificationCenter.default.publisher(for: .accessibilityStatusDidChange)
            .sink { [weak self] _ in
                if AccessibilityPermissionManager.shared.isAccessibilityEnabled {
                    self?.retryPendingMappings()
                }
            }
            .store(in: &cancellables)
    }
    
    func activateMapping(id: UUID, source: HotkeyData, target: HotkeyData) {
        if AccessibilityPermissionManager.shared.isAccessibilityEnabled {
            do {
                try ShortcutManager.shared.enableShortcutMapping(id: id, from: source, to: target)
                lastError = nil
            } catch {
                lastError = error.localizedDescription
                print("Erreur lors de l'activation du mapping : \(error)")
                // Désactiver le toggle en cas d'erreur
                if let index = ShortcutManager.shared.mappings.firstIndex(where: { $0.id == id }) {
                    ShortcutManager.shared.mappings[index].isEnabled = false
                }
            }
        } else {
            print("Les permissions d'accessibilité ne sont pas accordées")
            // Désactiver le toggle
            if let index = ShortcutManager.shared.mappings.firstIndex(where: { $0.id == id }) {
                ShortcutManager.shared.mappings[index].isEnabled = false
            }
        }
    }
    
    func deactivateMapping(id: UUID) {
        ShortcutManager.shared.disableShortcutMapping(id: id)
        removePendingMapping(id: id)
    }
    
    private var pendingMappings: [UUID: (source: HotkeyData, target: HotkeyData)] = [:]
    
    private func storePendingMapping(id: UUID, source: HotkeyData, target: HotkeyData) {
        pendingMappings[id] = (source, target)
    }
    
    private func removePendingMapping(id: UUID) {
        pendingMappings.removeValue(forKey: id)
    }
    
    private func retryPendingMappings() {
        for (id, mapping) in pendingMappings {
            activateMapping(id: id, source: mapping.source, target: mapping.target)
        }
        pendingMappings.removeAll()
    }
}
