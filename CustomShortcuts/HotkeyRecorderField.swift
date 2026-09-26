// HotkeyRecorderField.swift
import SwiftUI

class RecordingManager {
    static let shared = RecordingManager()
    private init() {}
    
    var globalEventMonitor: Any? = nil
    var currentlyRecordingField: UUID? = nil
    
    func stopCurrentRecording() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
            currentlyRecordingField = nil
        }
    }
}

struct FullOpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1.0) // Force l'opacité à rester à 1
    }
}

struct HotkeyRecorderField: View {
    @Binding var hotkeyData: HotkeyData?
    @Binding var isRecording: Bool
    let isDisabled: Bool
    let isAlternate: Bool
    @State private var isEditing = false
    @State private var editedText: String = ""
    @State private var isHovered = false
    @State private var isIconHovered = false

    @Environment(\.colorScheme) var colorScheme
    let id = UUID()
    
    init(hotkeyData: Binding<HotkeyData?>, isRecording: Binding<Bool>, isDisabled: Bool, isAlternate: Bool = false) {
        self._hotkeyData = hotkeyData
        self._isRecording = isRecording
        self.isDisabled = isDisabled
        self.isAlternate = isAlternate
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Text(hotkeyData?.toString() ?? NSLocalizedString("Shortcut", comment: ""))
                .foregroundColor(getTextColor())
                .opacity(hotkeyData == nil ? 0.5 : 1.0)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !isDisabled && (isHovered || isEditing) {
                Button(action: {
                    if isRecording {
                        stopRecording()
                        isRecording = false
                    }
                    editedText = hotkeyData?.toString() ?? ""
                    isEditing = true
                }) {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                        .foregroundColor(CustomColors.IconColor(isHovered: isHovered))
                        .opacity(isEditing ? 1.0 : (isIconHovered ? 1.0 : (isHovered ? 0.6 : 0.0)))
                        .font(.system(size: 12))
                }
                .buttonStyle(FullOpacityButtonStyle())
                .onHover { hovering in
                    isIconHovered = hovering
                }
                .popover(isPresented: $isEditing, arrowEdge: .bottom) {
                    PopoverContent(
                        editedText: $editedText,
                        isEditing: $isEditing,
                        hotkeyData: $hotkeyData
                    )
                }
            }
        }
        .frame(height: 28)
        .padding(.trailing, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(getBackgroundColor())
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isRecording ? CustomColors.recordingBorder : CustomColors.fieldBorder(isDisabled: isDisabled, isAlternate: isAlternate),
                    lineWidth: isRecording ? 2 : 1
                )
        )
        .onTapGesture {
            if !isDisabled {
                if isRecording {
                    stopRecording()
                    isRecording = false
                } else {
                    if let currentId = RecordingManager.shared.currentlyRecordingField, currentId != id {
                        RecordingManager.shared.stopCurrentRecording()
                        NotificationCenter.default.post(
                            name: NSNotification.Name("StopAllRecordings"),
                            object: nil
                        )
                    }
                    startRecording()
                    isRecording = true
                }
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StopAllRecordings"),
                object: nil,
                queue: .main
            ) { _ in
                if isRecording {
                    isRecording = false
                }
            }
        }
        .onDisappear {
            if isRecording {
                stopRecording()
                isRecording = false
            }
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("StopAllRecordings"),
                object: nil
            )
        }
        .onKeyPress(.escape) {
            if isRecording {
                stopRecording()
                isRecording = false
                DispatchQueue.main.async {
                    NSApp.mainWindow?.makeFirstResponder(nil)
                }
            }
            if isEditing {
                isEditing = false
            }
            return .handled
        }
    }
    
    private func getBackgroundColor() -> Color {
        return CustomColors.fieldBackground(isDisabled: isDisabled, isAlternate: isAlternate)
    }
    
    private func getTextColor() -> Color {
        if hotkeyData == nil {
            return Color.gray
        } else {
            return CustomColors.fieldText(isDisabled: isDisabled)
        }
    }
    
    private func startRecording() {
        print("Started recording for field \(id)...")
        
        RecordingManager.shared.stopCurrentRecording()
        RecordingManager.shared.currentlyRecordingField = id
        
        RecordingManager.shared.globalEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isRecording && RecordingManager.shared.currentlyRecordingField == id {
                if event.keyCode == 53 {
                    stopRecording()
                    isRecording = false
                    DispatchQueue.main.async {
                        NSApp.mainWindow?.makeFirstResponder(nil)
                    }
                    return nil
                }
                
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let keyCode = event.keyCode
                
                var character: String
                if modifiers.contains(.shift) {
                    character = event.characters ?? ""
                } else {
                    character = event.charactersIgnoringModifiers ?? ""
                }
                // Les touches mortes (^, ¨…) ne produisent aucun caractère, et ⌃ en produit un invisible
                // (ex. ⌃⇧A → "\u{01}") : on lit alors le caractère dans la disposition
                if character.isEmpty || character.unicodeScalars.allSatisfy({ CharacterSet.controlCharacters.contains($0) }) {
                    character = KeyboardLayout.character(for: keyCode, modifiers: modifiers.intersection(.shift)) ?? character
                }
                
                hotkeyData = HotkeyData(
                    keyCode: keyCode,
                    modifiers: modifiers,
                    character: character
                )
                
                stopRecording()
                isRecording = false
                return nil
            }
            return event
        }
    }
    
    private func stopRecording() {
        if RecordingManager.shared.currentlyRecordingField == id {
            RecordingManager.shared.stopCurrentRecording()
        }
    }
}



struct PopoverContent: View {
    @Binding var editedText: String
    @Binding var isEditing: Bool
    @Binding var hotkeyData: HotkeyData?
    @Environment(\.colorScheme) var colorScheme
    @State private var isSaveHovered = false
    @State private var isCancelHovered = false
    
    private let modifierKeys = [
        ("⌃", "Control"),
        ("⌥", "Option"),
        ("⇧", "Shift"),
        ("⌘", "Command")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // EmptyView().preferredColorScheme(colorScheme)
            
            Text(NSLocalizedString("Edit shortcut", comment: ""))
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)
            
            ZStack(alignment: .leading) {
                TextField("", text: $editedText)
                    .textFieldStyle(.plain)
                    .foregroundColor(editedText.isEmpty ? .gray : .primary)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 28)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)
            .onChange(of: editedText) { oldValue, newValue in
                let formatted = formattedText(newValue, previous: oldValue)
                if formatted != newValue {
                    editedText = formatted
                }
            }
            
            HStack(spacing: 4) {
                ForEach(modifierKeys, id: \.0) { symbol, name in
                    Button(action: { toggleModifier(symbol) }) {
                        Text(symbol)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(hasModifier(symbol)
                                          ? (colorScheme == .dark ? CustomColors.keysEnabledDark : CustomColors.keysEnabledLight)
                                          : (colorScheme == .dark ? CustomColors.keysDisabledDark : CustomColors.keysDisabledLight))
                            )
                            .foregroundColor(
                                colorScheme == .dark
                                    ? .white
                                    : CustomColors.textPrimary.opacity(hasModifier(symbol) ? 1.0 : 0.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(name)
                    }
                }
            .padding(.horizontal)
            Button(action: {
                if let newHotkeyData = parseEditedText(currentText()) {
                    hotkeyData = newHotkeyData
                }
                isEditing = false
            }) {
                Text(NSLocalizedString("Save", comment: ""))
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(isSaveHovered ? CustomColors.saveButtonHover : CustomColors.saveButton)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16) // Ajoute 16px de padding sur les côtés
            .padding(.bottom, 16)    // Ajoute 16px de padding en bas
            .animation(.easeInOut(duration: 0.16), value: isSaveHovered)
            .onHover { hover in
                isSaveHovered = hover
            }
        }
    }

    
    // Rest of the code remains the same
    private func hasModifier(_ modifier: String) -> Bool {
        editedText.contains(modifier)
    }
    
    // Texte réellement affiché dans le champ, mis en forme.
    // Une touche morte (^, ¨…) reste « en attente » : affichée mais absente de editedText.
    // On la valide comme le ferait macOS, puis on lit le champ directement car editedText
    // et sa mise en forme (onChange) ne sont pas encore à jour à cet instant.
    private func currentText() -> String {
        guard let editor = NSApp.keyWindow?.firstResponder as? NSTextView,
              editor.hasMarkedText() else {
            return editedText
        }
        let previousText = editedText
        let markedRange = editor.markedRange()
        let pendingText = (editor.string as NSString).substring(with: markedRange)
        editor.insertText(pendingText, replacementRange: markedRange)
        return formattedText(editor.string, previous: previousText)
    }
    
    private func withoutModifiers(_ text: String) -> String {
        text
            .replacingOccurrences(of: "⌃", with: "")
            .replacingOccurrences(of: "⌥", with: "")
            .replacingOccurrences(of: "⇧", with: "")
            .replacingOccurrences(of: "⌘", with: "")
    }
    
    // Modificateurs dans l'ordre standard (⌃⌥⇧⌘) suivis d'un seul caractère
    private func formattedText(_ text: String, previous: String) -> String {
        if text.isEmpty {
            return text
        }
        
        var modifiers = ""
        for modifier in ["⌃", "⌥", "⇧", "⌘"] where text.contains(modifier) {
            modifiers += modifier
        }
        
        // Garde le caractère nouvellement tapé plutôt que l'ancien (ex. "⌘Q" + "^" → "⌘^")
        let characters = withoutModifiers(text).filter { !$0.isWhitespace }
        let previousCharacter = withoutModifiers(previous)
        let character = characters.first(where: { String($0) != previousCharacter }) ?? characters.first
        
        return modifiers + (character.map(String.init) ?? "")
    }
    
    private func toggleModifier(_ modifier: String) {
        let text = currentText()
        if text.contains(modifier) {
            editedText = text.replacingOccurrences(of: modifier, with: "")
        } else {
            editedText = formattedText(modifier + text, previous: text)
        }
    }
    
    private func parseEditedText(_ text: String) -> HotkeyData? {
        var modifiers: NSEvent.ModifierFlags = []
        if text.contains("⌃") { modifiers.insert(.control) }
        if text.contains("⌥") { modifiers.insert(.option) }
        if text.contains("⇧") { modifiers.insert(.shift) }
        if text.contains("⌘") { modifiers.insert(.command) }
        
        let character = withoutModifiers(text).trimmingCharacters(in: .whitespaces)
        
        let singleCharacter = character.isEmpty ? "" : String(character.prefix(1))
        
        guard !singleCharacter.isEmpty,
              let key = KeyboardLayout.keyCode(for: singleCharacter) else {
            return nil
        }

        // Ajoute les modificateurs nécessaires pour produire le caractère (ex. ⇧ pour "?" en AZERTY)
        return HotkeyData(keyCode: key.keyCode, modifiers: modifiers.union(key.modifiers), character: singleCharacter)
    }
}
