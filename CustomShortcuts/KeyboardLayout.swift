// KeyboardLayout.swift
import AppKit
import Carbon

/// Traduction keyCode <-> caractère selon la disposition de clavier active (AZERTY, QWERTY, …).
/// S'appuie sur `UCKeyTranslate` avec `kUCKeyTranslateNoDeadKeysMask` pour que les touches mortes
/// (`^`, `¨`, `` ` ``…) renvoient leur caractère au lieu d'une chaîne vide.
/// Les API TIS doivent être appelées depuis le thread principal.
enum KeyboardLayout {
    // Touches modificatrices (⌘, ⇧, ⇪, ⌥, ⌃, fn) : elles ne produisent aucun caractère
    private static let modifierKeyCodes: ClosedRange<UInt16> = 54...63

    // Pavé numérique : consulté en dernier pour ne pas masquer les touches principales
    private static let keypadKeyCodes: [UInt16] = [65, 67, 69, 71, 75, 76, 78, 81, 82, 83, 84, 85, 86, 87, 88, 89, 91, 92]

    private static let mainKeyCodes: [UInt16] = (UInt16(0)...UInt16(127)).filter {
        !modifierKeyCodes.contains($0) && !keypadKeyCodes.contains($0)
    }

    // Couches consultées pour retrouver une touche, de la plus directe à la plus composée
    private static let lookupLayers: [NSEvent.ModifierFlags] = [[], [.shift], [.option], [.shift, .option]]

    /// Caractère produit par `keyCode` avec les modificateurs donnés (seuls ⇧ et ⌥ sont pris en compte).
    static func character(for keyCode: UInt16, modifiers: NSEvent.ModifierFlags = []) -> String? {
        withCurrentLayout { layout in
            translate(keyCode, modifiers: modifiers, layout: layout)
        }
    }

    /// Retrouve la touche physique qui produit `character` sur la disposition active.
    /// Les modificateurs renvoyés sont ceux nécessaires pour obtenir le caractère (ex. ⇧ pour `?` en AZERTY).
    static func keyCode(for character: String) -> (keyCode: UInt16, modifiers: NSEvent.ModifierFlags)? {
        withCurrentLayout { layout in
            for layer in lookupLayers {
                for keyCode in mainKeyCodes {
                    guard let produced = translate(keyCode, modifiers: layer, layout: layout) else { continue }
                    // Sur la couche de base, la casse est ignorée : "A" désigne la touche A
                    if produced == character || (layer.isEmpty && produced.lowercased() == character.lowercased()) {
                        return (keyCode, layer)
                    }
                }
            }

            for keyCode in keypadKeyCodes where translate(keyCode, modifiers: [], layout: layout) == character {
                return (keyCode, [])
            }

            return nil
        }
    }

    // MARK: - Privé

    private static func withCurrentLayout<T>(_ body: (UnsafePointer<UCKeyboardLayout>) -> T?) -> T? {
        // Certaines méthodes de saisie (japonais, chinois…) n'ont pas de disposition Unicode :
        // on se rabat alors sur la disposition ASCII associée
        guard let data = layoutData(from: TISCopyCurrentKeyboardLayoutInputSource())
                ?? layoutData(from: TISCopyCurrentASCIICapableKeyboardLayoutInputSource()) else {
            return nil
        }

        return data.withUnsafeBytes { buffer in
            guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return nil
            }
            return body(layout)
        }
    }

    private static func layoutData(from source: Unmanaged<TISInputSource>?) -> Data? {
        guard let source = source?.takeRetainedValue(),
              let rawData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        return Unmanaged<CFData>.fromOpaque(rawData).takeUnretainedValue() as Data
    }

    private static func translate(_ keyCode: UInt16, modifiers: NSEvent.ModifierFlags, layout: UnsafePointer<UCKeyboardLayout>) -> String? {
        var carbonModifiers = 0
        if modifiers.contains(.shift) { carbonModifiers |= shiftKey }
        if modifiers.contains(.option) { carbonModifiers |= optionKey }

        var deadKeyState: UInt32 = 0
        var characters = [UniChar](repeating: 0, count: 4)
        var length = 0

        let status = UCKeyTranslate(
            layout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            UInt32(carbonModifiers >> 8) & 0xFF,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            characters.count,
            &length,
            &characters
        )

        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: characters, count: length)
    }
}
