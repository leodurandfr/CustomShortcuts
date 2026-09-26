import Foundation
import Carbon
import AppKit

struct HotkeyData: Codable, Equatable {
    let keyCode: UInt16
    let modifiers: UInt
    let character: String
    
    // Initialisation standard
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, character: String) {
        self.keyCode = keyCode
        
        // Ne pas ajouter automatiquement .shift si le caractère est en majuscule
        // Utiliser uniquement les modificateurs fournis
        self.modifiers = modifiers.rawValue
        self.character = character
    }
    
    // Initialisation depuis un événement
    init?(from event: NSEvent) {
        guard let character = event.charactersIgnoringModifiers, !character.isEmpty else {
            return nil
        }
        
        self.keyCode = event.keyCode
        self.modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        self.character = character
    }
    
    var modifierFlags: NSEvent.ModifierFlags {
        return NSEvent.ModifierFlags(rawValue: modifiers)
    }
    
    func matches(_ event: NSEvent) -> Bool {
        let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Vérifier si la touche correspond
        let keyMatches = event.keyCode == keyCode
        
        // Vérifier si les modificateurs correspondent exactement
        let modifiersMatch = eventModifiers == modifierFlags
        
        return keyMatches && modifiersMatch && characterMatches(event)
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
        
        // Ne pas convertir en majuscule, utiliser le caractère tel quel
        result += character
        
        return result
    }
    
    // Méthodes supplémentaires pour Codable
    enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, character
    }
    
    // Vérification d'égalité
    static func == (lhs: HotkeyData, rhs: HotkeyData) -> Bool {
        return lhs.keyCode == rhs.keyCode &&
               lhs.modifiers == rhs.modifiers &&
               lhs.character == rhs.character
    }
}
