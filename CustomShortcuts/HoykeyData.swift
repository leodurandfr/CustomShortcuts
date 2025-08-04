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
        
        // Vérifier si le caractère correspond en ignorant la casse
        let charMatches = event.charactersIgnoringModifiers?.lowercased() == character.lowercased()
        
        return keyMatches && modifiersMatch && charMatches
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
