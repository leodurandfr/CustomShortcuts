import Foundation
import Carbon
import AppKit

struct HotkeyData: Codable, Equatable {
    let keyCode: UInt16
    let modifiers: UInt
    let character: String
    // Bouton de souris (2 = clic milieu, 3 et 4 = boutons latéraux…), nil pour une touche du clavier
    let mouseButton: Int?
    
    // Initialisation standard
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, character: String) {
        self.keyCode = keyCode
        
        // Ne pas ajouter automatiquement .shift si le caractère est en majuscule
        // Utiliser uniquement les modificateurs fournis
        self.modifiers = modifiers.rawValue
        self.character = character
        self.mouseButton = nil
    }
    
    // Seuls ces modificateurs définissent un raccourci : Caps Lock, fn, pavé numérique
    // ou les indicateurs internes des événements souris ne doivent pas empêcher la correspondance
    static let shortcutModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]
    
    // Initialisation pour un bouton de souris
    init(mouseButton: Int, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = 0
        self.modifiers = modifiers.intersection(Self.shortcutModifiers).rawValue
        self.character = ""
        self.mouseButton = mouseButton
    }
    
    // Initialisation depuis un événement
    init?(from event: NSEvent) {
        guard let character = event.charactersIgnoringModifiers, !character.isEmpty else {
            return nil
        }
        
        self.keyCode = event.keyCode
        self.modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        self.character = character
        self.mouseButton = nil
    }
    
    var isMouseButton: Bool {
        return mouseButton != nil
    }
    
    var modifierFlags: NSEvent.ModifierFlags {
        return NSEvent.ModifierFlags(rawValue: modifiers)
    }
    
    func matches(_ event: NSEvent) -> Bool {
        let eventModifiers = event.modifierFlags.intersection(Self.shortcutModifiers)
        
        // Vérifier si les modificateurs correspondent exactement
        guard eventModifiers == modifierFlags.intersection(Self.shortcutModifiers) else {
            return false
        }
        
        if let mouseButton = mouseButton {
            return event.type == .otherMouseDown && event.buttonNumber == mouseButton
        }
        
        // keyCode et characters ne sont valides que pour un événement clavier
        guard event.type == .keyDown else {
            return false
        }
        return event.keyCode == keyCode && characterMatches(event)
    }

    // Vérifie que la touche produit toujours le caractère enregistré : après un changement
    // de disposition (AZERTY → QWERTY), un même keyCode ne désigne plus la même touche
    private func characterMatches(_ event: NSEvent) -> Bool {
        if character.isEmpty || event.charactersIgnoringModifiers?.lowercased() == character.lowercased() {
            return true
        }

        // Une touche morte (^, ¨…) n'a pas de caractère dans l'événement : on le lit dans la disposition
        let layers: [NSEvent.ModifierFlags] = [[], [.shift], modifierFlags.intersection([.shift, .option])]
        let layoutCharacters = layers.compactMap { KeyboardLayout.character(for: keyCode, modifiers: $0) }

        // Disposition illisible : on se fie à la touche physique
        if layoutCharacters.isEmpty {
            return true
        }
        return layoutCharacters.contains { $0.lowercased() == character.lowercased() }
    }
    
    func toString() -> String {
        var result = ""
        let modifiers = self.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }
        
        if let mouseButton = mouseButton {
            // Numérotation usuelle : 1 = gauche, 2 = droit, 3 = milieu, 4 et 5 = latéraux
            result += String(format: NSLocalizedString("Mouse button %d", comment: ""), mouseButton + 1)
        } else {
            // Ne pas convertir en majuscule, utiliser le caractère tel quel
            result += character
        }
        
        return result
    }
    
    // Méthodes supplémentaires pour Codable
    enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, character, mouseButton
    }
    
    // Vérification d'égalité
    static func == (lhs: HotkeyData, rhs: HotkeyData) -> Bool {
        return lhs.keyCode == rhs.keyCode &&
               lhs.modifiers == rhs.modifiers &&
               lhs.character == rhs.character &&
               lhs.mouseButton == rhs.mouseButton
    }
}
