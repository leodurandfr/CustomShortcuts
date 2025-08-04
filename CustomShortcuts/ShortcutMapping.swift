import Foundation

struct ShortcutMapping: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String?
    var sourceHotkey: HotkeyData?
    var targetHotkey: HotkeyData?
    var isEnabled: Bool
    var context: String  // "system" ou bundleIdentifier de l'application
    
    init(context: String = "system") {
        self.id = UUID()
        self.sourceHotkey = nil
        self.targetHotkey = nil
        self.isEnabled = false
        self.context = context
    }
    
    // Initialisation personnalisée pour créer facilement un mapping
    init(id: UUID = UUID(), name: String? = nil, sourceHotkey: HotkeyData? = nil,
         targetHotkey: HotkeyData? = nil, isEnabled: Bool = false, context: String = "system") {
        self.id = id
        self.name = name
        self.sourceHotkey = sourceHotkey
        self.targetHotkey = targetHotkey
        self.isEnabled = isEnabled
        self.context = context
    }
    
    // Méthode pour cloner un mapping
    func clone() -> ShortcutMapping {
        return ShortcutMapping(
            id: UUID(), // Nouveau UUID pour éviter les conflits
            name: self.name != nil ? "\(self.name!) (copie)" : nil,
            sourceHotkey: self.sourceHotkey,
            targetHotkey: self.targetHotkey,
            isEnabled: false, // La copie est désactivée par défaut
            context: self.context
        )
    }
    
    // Pour faciliter le débogage
    var description: String {
        let sourceName = sourceHotkey?.toString() ?? "Non défini"
        let targetName = targetHotkey?.toString() ?? "Non défini"
        let status = isEnabled ? "Activé" : "Désactivé"
        return "\(name ?? "Sans nom"): \(sourceName) -> \(targetName) [\(status)] (\(context))"
    }
}
